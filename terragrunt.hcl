remote_state {
  backend = "s3"
  generate = {
    path      = "state.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    profile = "guardian"
    role_arn = "arn:aws:iam::934643182396:role/terraform"
    bucket = "guardian-terraform-state"

    key = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "aws" {
  region  = "us-east-1"
  profile = "guardian"

  assume_role {
    role_arn = "arn:aws:iam::934643182396:role/terraform"
  }
}
EOF
}