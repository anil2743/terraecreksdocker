

  # VPC
  resource "aws_vpc" "html_db_vpc" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags = {
      Name = "html-db-vpc"
    }
  }

  # Internet Gateway
  resource "aws_internet_gateway" "html_db_igw" {
    vpc_id = aws_vpc.html_db_vpc.id
    tags = {
      Name = "html-db-igw"
    }
  }

  # Public Subnets (Multiple AZs)
  resource "aws_subnet" "html_db_public_subnet_1" {
    vpc_id                  = aws_vpc.html_db_vpc.id
    cidr_block              = "10.0.10.0/24"
    map_public_ip_on_launch = true
    availability_zone       = "${var.aws_region}a"
    tags = {
      Name = "html-db-public-subnet-1"
    }
  }

  resource "aws_subnet" "html_db_public_subnet_2" {
    vpc_id                  = aws_vpc.html_db_vpc.id
    cidr_block              = "10.0.20.0/24"
    map_public_ip_on_launch = true
    availability_zone       = "${var.aws_region}b"
    tags = {
      Name = "html-db-public-subnet-2"
    }
  }

  # Private Subnets (Multiple AZs)
  resource "aws_subnet" "html_db_private_subnet_1" {
    vpc_id            = aws_vpc.html_db_vpc.id
    cidr_block        = "10.0.30.0/24"
    availability_zone = "${var.aws_region}a"
    tags = {
      Name = "html-db-private-subnet-1"
    }
  }

  resource "aws_subnet" "html_db_private_subnet_2" {
    vpc_id            = aws_vpc.html_db_vpc.id
    cidr_block        = "10.0.40.0/24"
    availability_zone = "${var.aws_region}b"
    tags = {
      Name = "html-db-private-subnet-2"
    }
  }

  # Route Table for Public Subnets
  resource "aws_route_table" "html_db_public_rt" {
    vpc_id = aws_vpc.html_db_vpc.id
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.html_db_igw.id
    }
    tags = {
      Name = "html-db-public-rt"
    }
  }

  # Route Table for Private Subnets
  resource "aws_route_table" "html_db_private_rt" {
    vpc_id = aws_vpc.html_db_vpc.id
    tags = {
      Name = "html-db-private-rt"
    }
  }

  # NAT Gateway (Updated to use domain)
  resource "aws_eip" "html_db_nat_eip" {
    domain = "vpc"
  }

  resource "aws_nat_gateway" "html_db_nat_gw" {
    allocation_id = aws_eip.html_db_nat_eip.id
    subnet_id     = aws_subnet.html_db_public_subnet_1.id
    tags = {
      Name = "html-db-nat-gw"
    }
  }

  # Route for Private Subnets to NAT Gateway
  resource "aws_route" "html_db_private_nat_route_1" {
    route_table_id         = aws_route_table.html_db_private_rt.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id         = aws_nat_gateway.html_db_nat_gw.id
  }

  # Associate Route Tables with Subnets
  resource "aws_route_table_association" "html_db_public_rt_assoc_1" {
    subnet_id      = aws_subnet.html_db_public_subnet_1.id
    route_table_id = aws_route_table.html_db_public_rt.id
  }

  resource "aws_route_table_association" "html_db_public_rt_assoc_2" {
    subnet_id      = aws_subnet.html_db_public_subnet_2.id
    route_table_id = aws_route_table.html_db_public_rt.id
  }

  resource "aws_route_table_association" "html_db_private_rt_assoc_1" {
    subnet_id      = aws_subnet.html_db_private_subnet_1.id
    route_table_id = aws_route_table.html_db_private_rt.id
  }

  resource "aws_route_table_association" "html_db_private_rt_assoc_2" {
    subnet_id      = aws_subnet.html_db_private_subnet_2.id
    route_table_id = aws_route_table.html_db_private_rt.id
  }

  # ECR Repository
  resource "aws_ecr_repository" "html_db_repo" {
    name = "html-db-app"
  }

  # EKS Cluster
  resource "aws_eks_cluster" "html_db_cluster" {
    name     = "html-db-eks-cluster"
    role_arn = aws_iam_role.eks_role.arn
    vpc_config {
      subnet_ids = [aws_subnet.html_db_private_subnet_1.id, aws_subnet.html_db_private_subnet_2.id]
    }
  }

  resource "aws_iam_role" "eks_role" {
    name = "html-db-eks-role"
    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "eks.amazonaws.com"
          }
        }
      ]
    })
  }

  resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role       = aws_iam_role.eks_role.name
  }

  # EKS Node Group
  resource "aws_eks_node_group" "html_db_node_group" {
    cluster_name    = aws_eks_cluster.html_db_cluster.name
    node_group_name = "html-db-node-group"
    node_role_arn   = aws_iam_role.eks_node_role.arn
    subnet_ids      = [aws_subnet.html_db_private_subnet_1.id, aws_subnet.html_db_private_subnet_2.id]
    scaling_config {
      desired_size = 2
      max_size     = 3
      min_size     = 1
    }
    instance_types = ["t3.medium"]
  }

  resource "aws_iam_role" "eks_node_role" {
    name = "html-db-eks-node-role"
    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "ec2.amazonaws.com"
          }
        }
      ]
    })
  }

  resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role       = aws_iam_role.eks_node_role.name
  }

  resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role       = aws_iam_role.eks_node_role.name
  }

  resource "aws_iam_role_policy_attachment" "ec2_container_registry_readonly" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role       = aws_iam_role.eks_node_role.name
  }
