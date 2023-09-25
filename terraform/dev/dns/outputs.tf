output "route53_zone_id" {
  value = module.route_53_subdomain.route53_zone_id
}

output "acm_master_certificate_arn" {
  value = module.route_53_subdomain.acm_master_certificate_arn
}

output "acm_features_certificate_arn" {
  value = module.route_53_subdomain.acm_features_certificate_arn
}

output "dns_address" {
  value = module.route_53_subdomain.dns_address
}