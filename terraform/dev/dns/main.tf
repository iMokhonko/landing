terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "tf-state-backend-imokhonko"
    key    = "www/dev/dns.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
  profile = "default"
}

module "route_53_subdomain" {
  source = "../../../terraform-modules/web-ui/route_53_subdomain"

  env = var.env
  dns_service_name = var.dns_service_name
  hosted_zone = var.hosted_zone
}