variable "dns_service_name" {
  type = string
  default = "www"
}

variable "hosted_zone" {
  type = string
  default = "imokhonko.com"
}

variable "env" {
  type = string
  default = "dev"
}

variable "feature" {
  type = string
  default = "master"
}

variable "route53_zone_id" {
  type = string
}

variable "acm_master_certificate_arn" {
  type = string
}

variable "acm_features_certificate_arn" {
  type = string
}


variable "s3_bucket_arn" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

variable "s3_bucket_bucket_domain_name" {
  type = string
}