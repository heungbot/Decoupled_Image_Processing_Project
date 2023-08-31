provider "aws" {
  region = "ap-northeast-2"

  default_tags {
    tags = {
      Project  = "image_processing"
      Managing = "terraform"
    }
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket = "heungbot-terraform-state-bucket"
    key    = "state/image-processing/terraform_state.tfstate"
    region = "ap-northeast-2"
  }
}