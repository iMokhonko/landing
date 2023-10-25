output "s3_bucket_name" {
 value = module.s3_bucket.s3_bucket_id
}

output "s3_bucket_arn" {
  value = module.s3_bucket.s3_bucket_arn
}

output "s3_bucket_bucket_domain_name" {
  value = module.s3_bucket.s3_bucket_bucket_domain_name
}