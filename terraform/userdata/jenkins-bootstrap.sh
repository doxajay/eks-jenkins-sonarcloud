#!/usr/bin/env bash
set -euxo pipefail

ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASS="${ADMIN_PASS:-ChangeMe_123!}"
CREATE_CREDS="${CREATE_CREDS:-false}"
SONAR_TOKEN="${SONAR_TOKEN:-}"
TFC_TOKEN="${TFC_TOKEN:-}"
AWS_REGION="${AWS_REGION:-us-west-2}"

# -------- System prep --------
apt-get update -y
apt-get install -y fontconfig openjdk-17-jre docker.io git unzip curl gnupg lsb-release

# Docker permissions
usermod -aG docker ubuntu || true

# -------- Jenkins install (LTS) --------
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee \
  /usr/share/keyrings/jenkins-keyring.asc >/dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list
apt-get update -y
apt-get install -y jenkins

# Allow jenkins user to use Docker
usermod -aG docker jenkins || true

# -------- AWS CLI v2 --------
curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

# -------- kubectl (stable) --------
curl -sSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -sSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x /usr/local/bin/kubectl

# -------- Terraform (1.8.x) --------
TF_VERSION="1.8.5"
curl -sSL -o /tmp/terraform.zip "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip"
unzip -q /tmp/terraform.zip -d /usr/local/bin

# -------- SonarScanner CLI --------
SCANNER_VERSION="5.0.1.3006"
curl -sSL -o /tmp/sonar-scanner.zip \
  "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SCANNER_VERSION}-linux.zip"
unzip -q /tmp/sonar-scanner.zip -d /opt
echo "export PATH=/opt/sonar-scanner-${SCANNER_VERSION}-linux/bin:\$PATH" >/etc/profile.d/sonarscanner.sh

# -------- Preinstall key Jenkins plugins --------
PLUGINS="workflow-aggregator git aws-credentials docker-workflow sonar quality-gates job-dsl credentials-binding"
echo "${PLUGINS}" | tr ' ' '\n' > /var/lib/jenkins/plugins.txt
chown jenkins:jenkins /var/lib/jenkins/plugins.txt

# Install CLI
curl -fsSL -o /usr/local/bin/jenkins-plugin-cli https://github.com/jenkinsci/plugin-installation-manager-tool/releases/latest/download/jenkins-plugin-cli-2.12.15.jar
cat >/usr/local/bin/jpcli <<'EOF'
#!/usr/bin/env bash
exec java -jar /usr/local/bin/jenkins-plugin-cli "$@"
EOF
chmod +x /usr/local/bin/jpcli

systemctl stop jenkins || true
sudo -u jenkins bash -lc "/usr/local/bin/jpcli --plugin-file /var/lib/jenkins/plugins.txt --verbose"
systemctl start jenkins
systemctl enable jenkins

# -------- Disable setup wizard & create admin user --------
mkdir -p /var/lib/jenkins/init.groovy.d
cat >/var/lib/jenkins/init.groovy.d/basic-security.groovy <<'EOF'
import jenkins.model.*
import hudson.security.*

def instance = Jenkins.get()
instance.setInstallState(jenkins.install.InstallState.INITIAL_SETUP_COMPLETED)

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount(System.getenv("ADMIN_USER"), System.getenv("ADMIN_PASS"))
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

instance.save()
EOF
chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d

# -------- Optionally create credentials (SonarCloud & TFC) --------
if [ "${CREATE_CREDS}" = "true" ]; then
  cat >/var/lib/jenkins/init.groovy.d/credentials.groovy <<'EOF'
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl
import hudson.util.Secret

def store = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

def addOrUpdateSecret(id, desc, secret) {
  def existing = CredentialsProvider.lookupCredentials(
    com.cloudbees.plugins.credentials.common.StandardCredentials.class,
    Jenkins.instance, null, null
  ).find { it.id == id }
  if (existing != null) {
    store.updateCredentials(Domain.global(), existing, new StringCredentialsImpl(CredentialsScope.GLOBAL, id, desc, Secret.fromString(secret)))
  } else {
    store.addCredentials(Domain.global(), new StringCredentialsImpl(CredentialsScope.GLOBAL, id, desc, Secret.fromString(secret)))
  }
}

def sonarToken = System.getenv("SONAR_TOKEN")
def tfcToken = System.getenv("TFC_TOKEN")

if (sonarToken?.trim()) {
  addOrUpdateSecret("sonar-token", "SonarCloud Token", sonarToken)
}
if (tfcToken?.trim()) {
  addOrUpdateSecret("tfc-token", "Terraform Cloud Token", tfcToken)
}

Jenkins.instance.save()
EOF
  chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d
fi

# -------- Convenience banner --------
echo "Jenkins is ready. Login: ${ADMIN_USER} / (password hidden)"
echo "URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-hostname):8080/"
