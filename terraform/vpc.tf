# =====================================================
# VPC (Networking Foundation)
# =====================================================
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  name = "${var.project_name}-vpc"
  cidr = "10.42.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  public_subnets  = ["10.42.1.0/24", "10.42.2.0/24"]
  private_subnets = ["10.42.11.0/24", "10.42.12.0/24"]

  enable_nat_gateway      = true
  single_nat_gateway      = true
  map_public_ip_on_launch = true # Ensures EC2s in public subnets get public IPs automatically

  tags = {
    Project = var.project_name
  }
}
