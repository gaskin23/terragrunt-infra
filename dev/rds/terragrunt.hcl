terraform {
  source = "git::https://github.com/gaskin23/guardian-terraform.git//rds?ref=v1.5.9"
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
  rds_db_name              = "guardiandb"
  rds_username             = "postgres"
  rds_db_subnet_group_name = "guardian" 
  eks_name = dependency.eks.outputs.eks_name

  # Assuming the VPC ID and subnet IDs are outputs from the VPC and subnet configurations
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids

}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    private_subnet_ids = ["subnet-1234", "subnet-5678"]
  }
}


dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    eks_name            = "guardian"
    openid_provider_arn = "arn:aws:iam::934643182396:oidc-provider"
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