locals {
  hosted_zone_name = "${var.config.subdomain}${var.env != "prod" ? ".${var.env}" : ""}"
}

# pull data about hoster zone for provided domain
# hosted zone should be initialized before this execution
data "aws_route53_zone" "primary" {
  name         = "${var.config.hostedZone}."
  private_zone = false
}

# Create ACM certificate for domain and features
resource "aws_acm_certificate" "master_certificate" {
  domain_name = "${local.hosted_zone_name}.${var.config.hostedZone}"

  validation_method = "DNS"

  tags = var.tags
}

# Create ACM certificate for domain zone apex 
resource "aws_acm_certificate" "zone_apex_certificate" {
  count = var.env != "prod" ? 0 : 1

  domain_name = "${var.config.hostedZone}"

  validation_method = "DNS"

  tags = var.tags
}

# Create ACM certificate for domain and features
resource "aws_acm_certificate" "features_certificate" {
  count = var.env != "prod" ? 1 : 0

  domain_name = "*.${local.hosted_zone_name}.${var.config.hostedZone}"

  validation_method = "DNS"

  tags = var.tags
}

# create validation records for master certificate in hosted zone for acm certificate
resource "aws_route53_record" "acm_master_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.master_certificate.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = data.aws_route53_zone.primary.id
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.primary.id

  depends_on = [aws_acm_certificate.master_certificate]
}

# create validation records for zone apex acm certificate
resource "aws_route53_record" "acm_zone_apex_validation_record" {
  for_each = {
    for dvo in var.env != "prod" ? [] : aws_acm_certificate.zone_apex_certificate[0].domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = data.aws_route53_zone.primary.id
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id

  depends_on = [aws_acm_certificate.zone_apex_certificate]
}

# create validation records for features certificate in hosted zone for acm certificate
resource "aws_route53_record" "acm_features_validation_record" {
  for_each = {
    for dvo in var.env != "prod" ? aws_acm_certificate.features_certificate[0].domain_validation_options : [] : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = data.aws_route53_zone.primary.id
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id

  depends_on = [aws_acm_certificate.features_certificate]
}

resource "aws_acm_certificate_validation" "master_acm_validation" {
  certificate_arn         = aws_acm_certificate.master_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_master_validation_record : record.fqdn]

  depends_on = [aws_route53_record.acm_master_validation_record]
}

resource "aws_acm_certificate_validation" "zone_apex_acm_validation" {
  count = var.env != "prod" ? 0 : 1

  certificate_arn         = aws_acm_certificate.zone_apex_certificate[0].arn
  validation_record_fqdns = [for record in aws_route53_record.acm_zone_apex_validation_record : record.fqdn]

  depends_on = [aws_route53_record.acm_zone_apex_validation_record]
}

resource "aws_acm_certificate_validation" "features_acm_validation" {
  count = var.env != "prod" ? 1 : 0

  certificate_arn         = aws_acm_certificate.features_certificate[0].arn
  validation_record_fqdns = [for record in aws_route53_record.acm_features_validation_record : record.fqdn]

  depends_on = [aws_route53_record.acm_features_validation_record]
}


