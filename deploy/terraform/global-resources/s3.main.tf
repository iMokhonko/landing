module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket_prefix = "${var.env}-${var.config.subdomain}-"
  force_destroy = true
  tags = var.tags
}