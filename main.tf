provider "aws" {
  region = "eu-north-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name = "availability-zone"
    values = ["eu-north-1a", "ueu-north-1b", "eu-north-1c"]
  }
}

resource "aws_iam_role" "eks_role" {
  name = "eks-cluster-role1"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Action = [
                "sts:AssumeRole",
                "sts:TagSession"
            ]
            Effect = "Allow"
            Principal = {
                Service = "eks.amazonaws.com"
            }
        },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_policy" {
  role = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "Cluster" {
  name = "Cluster"
  access_config {
    authentication_mode = "API"
  }
  role_arn = aws_iam_role.eks_role.arn
  version = "1.31"
  vpc_config {
    subnet_ids = data.aws_subnets.default.ids
  }
  depends_on = [ aws_iam_role_policy_attachment.eks_policy ]
}

resource "aws_iam_role" "eks_nodes_roles" {
  name = "terraform_eks_node_group_role"
  assume_role_policy = jsonencode({
    Statement = [{
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
            Service = "ec2.amazonaws.com"
        }
    }]
    Version ="2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.eks_nodes_roles.name
}

resource "aws_iam_role_policy_attachment" "eks_CNI_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role = aws_iam_role.eks_nodes_roles.name
}

resource "aws_iam_role_policy_attachment" "ec2_registry_readonly_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = aws_iam_role.eks_nodes_roles.name
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_minimal_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy"
  role = aws_iam_role.eks_nodes_roles.name
}

resource "aws_eks_node_group" "eks_nodes" {
  cluster_name = aws_eks_cluster.Cluster.name
  node_group_name = "Nodes"
  node_role_arn = aws_iam_role.eks_nodes_roles.arn

  ami_type = "AL2023_x86_64_STANDARD"
  capacity_type = "ON_DEMAND"
  instance_types = ["c7i-flex.large"]
  disk_size = 20

  subnet_ids = data.aws_subnets.default.ids
  
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_worker_node_minimal_policy,
    aws_iam_role_policy_attachment.eks_CNI_policy,
    aws_iam_role_policy_attachment.ec2_registry_readonly_policy
  ]
  scaling_config {
    desired_size = 1
    max_size = 2
    min_size = 1
  }

  update_config {
    max_unavailable = 1
  }
}
