terraform {
  source = "git::https://terraform:${env.GH_TOKEN}@github.com/gaskin23/terraform-modules.git//kubernetes-addons?ref=v1.8.8"

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
  env      = include.env.locals.env
  eks_name = dependency.eks.outputs.eks_name
  openid_provider_arn = dependency.eks.outputs.openid_provider_arn
  enable_cluster_autoscaler      = true
  cluster_autoscaler_helm_verion = "9.28.0"
  vpc_id = dependency.vpc.outputs.vpc_id
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    eks_name            = "guardian"
    openid_provider_arn = "arn:aws:iam::934643182396:oidc-provider"
  }
}
dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    private_subnet_ids = ["subnet-1234", "subnet-5678"]
    vpc_id = ["vpc-06e4ab6c6cEXAMPLE"]
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