terraform {
  source = "git::https://terraform:${env.GH_TOKEN}@github.com/gaskin23/terraform-modules.git//eks?ref=v1.8.8"

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
  eks_version = "1.29"
  env         = include.env.locals.env
  eks_name    = "demo"
  subnet_ids  = dependency.vpc.outputs.private_subnet_ids
  vpc_id = dependency.vpc.outputs.vpc_id
  node_groups = {
    general = {
      capacity_type  = "ON_DEMAND"
      instance_types = ["t3a.xlarge"]
      scaling_config = {
        desired_size = 2
        max_size     = 10
        min_size     = 2
      }
    }
  }
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    private_subnet_ids = ["subnet-1234", "subnet-5678"]
    vpc_id = ["vpc-06e4ab6c6cEXAMPLE"]
  }
}