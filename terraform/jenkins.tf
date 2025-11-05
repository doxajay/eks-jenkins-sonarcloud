# =====================================================
# Jenkins Server Provisioning (Terraform-managed EC2)
# =====================================================

# -----------------------------------------------------
# Get latest Ubuntu 22.04 LTS AMI
# -----------------------------------------------------
data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# -----------------------------------------------------
# Security Group for Jenkins
# -----------------------------------------------------
resource "aws_security_group" "jenkins_sg" {
  name        = "${var.project_name}-jenkins-sg"
  description = "Allow HTTP(8080) and SSH(22) for Jenkins"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.jenkins_allowed_cidr_http]
  }

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.jenkins_allowed_cidr_ssh]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-jenkins-sg"
    Project = var.project_name
  }
}

# -----------------------------------------------------
# IAM Role and Instance Profile for Jenkins
# -----------------------------------------------------
resource "aws_iam_role" "jenkins_role" {
  name = "${var.project_name}-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Attach permissions for ECR, EKS, CloudWatch, and SSM (supported policies)
resource "aws_iam_role_policy_attachment" "jenkins_ecr" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "jenkins_eks_cluster" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "jenkins_eks_service" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role_policy_attachment" "jenkins_cloudwatch" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_role_policy_attachment" "jenkins_ssm" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "${var.project_name}-jenkins-profile"
  role = aws_iam_role.jenkins_role.name
}

# -----------------------------------------------------
# Jenkins User Data Template
# -----------------------------------------------------
data "template_file" "jenkins_userdata" {
  template = file("${path.module}/userdata/jenkins-bootstrap.sh")

  vars = {
    ADMIN_USER   = var.jenkins_admin_username
    ADMIN_PASS   = var.jenkins_admin_password
    CREATE_CREDS = var.create_jenkins_credentials ? "true" : "false"
    SONAR_TOKEN  = var.sonarcloud_token
    TFC_TOKEN    = var.tfc_token
    AWS_REGION   = var.region
  }
}

# -----------------------------------------------------
# EC2 Instance for Jenkins (protected)
# -----------------------------------------------------
resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = var.jenkins_instance_type
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.jenkins_profile.name
  user_data                   = data.template_file.jenkins_userdata.rendered

  # Extra safety against console/API termination
  disable_api_termination = true

  # ===== Protection so 'terraform apply' won't destroy/replace Jenkins =====
  lifecycle {
    # Block any destroy (including replacements) unless you temporarily remove this.
    prevent_destroy = true

    # Avoid unintended replacement when AMI updates or when user_data changes.
    # (If you *intend* to rotate AMI or userdata, comment these out for that run.)
    ignore_changes = [
      ami,
      user_data
    ]
  }

  tags = {
    Name    = "${var.project_name}-jenkins"
    Project = var.project_name
  }
}

# -----------------------------------------------------
# Outputs handled in outputs.tf
# -----------------------------------------------------
