terraform {
  backend "s3" {
    bucket = "open-jupyter-ubc-ca-terraform-tfstate"
    key    = "terraform.tfstate"
    region = "ca-central-1"

    # Enable locking via DynamoDB
    #dynamodb_table = "terraform-state-lock-dynamo"
    encrypt = true
  }
}
