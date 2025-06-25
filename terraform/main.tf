# ----------------------------------------
# ✅ VPC
# ----------------------------------------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# ----------------------------------------
# ✅ Subnets
# ----------------------------------------
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
}

# ----------------------------------------
# ✅ Internet Gateway + Route Table
# ----------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public1_rt" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public2_rt" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public_rt.id
}

# ----------------------------------------
# ✅ EKS Cluster + Node Group
# ----------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.13.1"

  cluster_name    = "java-cluster"
  cluster_version = "1.29"

  vpc_id      = aws_vpc.main.id
  subnet_ids  = [aws_subnet.public1.id, aws_subnet.public2.id]
  enable_irsa = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      max_size       = 3
      min_size       = 1
    }
  }
}

# ----------------------------------------
# ✅ ECR Repo
# ----------------------------------------
resource "aws_ecr_repository" "repo" {
  name         = "mywebapp"
  force_delete = true
}

# ----------------------------------------
# ✅ EC2 Instance for Admin (Self-hosted runner)
# ----------------------------------------
resource "aws_instance" "devops_admin" {
  ami                         = "ami-0f58b397bc5c1f2e8" # Ubuntu 22.04 LTS
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public1.id
  associate_public_ip_address = true
  key_name                    = "terraform2"
  vpc_security_group_ids      = [module.eks.cluster_primary_security_group_id]

  tags = {
    Name = "devops-admin"
  }
}
