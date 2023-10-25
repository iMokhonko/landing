output "route53_zone_id" {
  value = data.aws_route53_zone.primary.id
}

output "acm_master_certificate_arn" {
  value = aws_acm_certificate.master_certificate.arn
}

output "acm_zone_apex_certificate_arn" {
  value = var.env != "prod" ? "" : aws_acm_certificate.zone_apex_certificate[0].arn
}

output "acm_features_certificate_arn" {
  value = var.env != "prod" ? aws_acm_certificate.features_certificate[0].arn : ""
}

output "dns_address" {
  value = "${local.hosted_zone_name}.${var.config.hostedZone}"
}