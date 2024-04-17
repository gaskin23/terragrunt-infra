locals {
  enable_rds = false # Set to false to disable RDS deployment
}

terraform {
  source = "git::https://github.com/gaskin23/guardian-terraform.git//rds?ref=v1.8.9"

  # Conditionally skip the terraform module based on enable_rds variable
  skip = !local.enable_rds
}

include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

inputs = {
  rds_allocated_storage    = 20
  rds_storage_type         = "gp2"
  rds_engine               = "postgres"
  rds_engine_version       = "15.6"
  rds_instance_class       = "db.t3.micro"
  rds_db_name              = "keycloak"
  rds_username             = "postgres"
  rds_db_subnet_group_name = "guardian" 
  eks_name = dependency.eks.outputs.eks_name
  eks_worker_security_group_id = dependency.eks.outputs.eks_worker_security_group_id

  # Assuming the VPC ID and subnet IDs are outputs from the VPC and subnet configurations
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  vpc_id = dependency.vpc.outputs.vpc_id

}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    private_subnet_ids = ["subnet-1234", "subnet-5678"]
    vpc_id = ["vpc-06e4ab6c6cEXAMPLE"]
  }
}


dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    eks_name            = "guardian"
    openid_provider_arn = "arn:aws:iam::934643182396:oidc-provider"
    eks_worker_security_group_id = ["sg-123456"]
  }
}

generate "helm_provider" {
  path      = "helm-provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF

data "aws_eks_cluster" "eks" {
    name = var.eks_name
}

data "aws_eks_cluster_auth" "eks" {
    name = var.eks_name
}
provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}
EOF
}