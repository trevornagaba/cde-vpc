terraform {
  cloud {
    organization = "trevornagaba"
    workspaces {
      name = "cde-vpc"
    }
  }
  ## Used to provision infrastrcture; in this case aws
  ## These can be foound in the terraform registry 
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.33"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}