terraform {
  backend "s3" {
    bucket  = "randomcoww-tfstate"
    key     = "resources-012.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}

provider "aws" {
  region = "us-west-2"
}