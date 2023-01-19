provider "aws" {
  #profile = "default"
  region  = var.region
}

provider "random" {
}

provider "local" {
}

provider "null" {
}
