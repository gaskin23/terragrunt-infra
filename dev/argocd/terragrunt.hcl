terraform {
  source = "git::https://terraform:${env.GH_TOKEN}@github.com/gaskin23/terraform-modules.git//argocd?ref=v1.8.8"
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
  enable_argocd = false
  env      = include.env.locals.env
  eks_name = dependency.eks.outputs.eks_name
  argocd_k8s_namespace = "argocd"
  argocd_chart_version = "6.7.7"
  argocd_chart_name = "argo-cd"
  openid_provider_arn = dependency.eks.outputs.openid_provider_arn
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    eks_name            = "dev-demo"
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