terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "tf-state-backend-imokhonko"
    key    = "www/prod/cloudfront_distribution.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
  profile = "default"
}

module "distribution" {
  source = "../../../terraform-modules/web-ui/cloudfront_distribution"

  feature = var.feature
  dns_service_name = var.dns_service_name
  env = var.env
  hosted_zone = var.hosted_zone

  route53_zone_id = var.route53_zone_id
  acm_master_certificate_arn = var.acm_master_certificate_arn
  acm_features_certificate_arn = var.acm_features_certificate_arn

  s3_bucket_arn = var.s3_bucket_arn
  s3_bucket_name = var.s3_bucket_name
  s3_bucket_bucket_domain_name = var.s3_bucket_bucket_domain_name
}