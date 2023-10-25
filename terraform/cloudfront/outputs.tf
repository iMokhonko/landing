output "master_feature_cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.master_feature_distribution.id
}

output "zone_apex_cloudfront_distribution_id" {
  value = var.env != "prod" ? "" : aws_cloudfront_distribution.zone_apex_distribution[0].id
}

output "features_cloudfront_distribution_id" {
  value = var.env != "prod" ? aws_cloudfront_distribution.features_distribution[0].id : null
}