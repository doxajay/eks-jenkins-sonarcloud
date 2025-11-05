from flask import Flask

app = Flask(__name__)

@app.route("/")
def home():
    services = [
        "Terraform Cloud (remote backend + IaC workflow)",
        "AWS (VPC, EC2, ECR, EKS, CloudWatch)",
        "Jenkins (CI/CD automation on EC2)",
        "Docker (container build/push)",
        "kubectl/eksctl (EKS deploy)"
    ]
    html = """
    <h2>This is a test of the concept and if you see this screen, it means deployment was successful</h2>
    <h4>Services used:</h4>
    <ul>{}</ul>
    """.format("".join(f"<li>{s}</li>" for s in services))
    return html

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
