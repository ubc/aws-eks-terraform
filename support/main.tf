variable "aws_region" {
  description = "The AWS region things are created in"
  default     = "ca-central-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  shared_credentials_files = ["$HOME/.aws/credentials"]
  #  profile                 = "default"
  region = var.aws_region
}

# create a dynamodb table for locking the state file
resource "aws_dynamodb_table" "terraform-locks" {
  name         = "terraformlocks-openjupyter"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name    = "DynamoDB Terraform State Lock Table"
    project = "jupyterhub"
  }
}
