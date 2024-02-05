locals {
  hasEnv = var.env != "prod"

  master_dns_record = "${var.config.subdomain}${local.hasEnv ? ".${var.env}" : ""}"
  features_dns_record = "*.${var.config.subdomain}${local.hasEnv ? ".${var.env}" : ""}"
}

# Create origin access control for cloudfront s3
resource "aws_cloudfront_origin_access_control" "access_control_origin" {
  name                              = "${local.master_dns_record} origin access control"
  description                       = "S3 bucket policy for cloudfront distribution"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Create cloudfront distribution for master feature
resource "aws_cloudfront_distribution" "master_feature_distribution" {
  origin {
    domain_name = module.s3_bucket.s3_bucket_bucket_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.access_control_origin.id
    origin_id                = "${local.master_dns_record} distribution id"
    origin_path              = "/master" 
  }
  
  enabled             = true
  comment             = "${local.master_dns_record} master feature"
  default_root_object = "index.html"

  aliases = ["${local.master_dns_record}.${var.config.hostedZone}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.master_dns_record} distribution id"

    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  custom_error_response {
    error_caching_min_ttl = 300
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_caching_min_ttl = 300
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.master_certificate.arn
    
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = var.tags
}

# Create cloudfront distribution for master feature
resource "aws_cloudfront_distribution" "features_distribution" {
  count = var.env != "prod" ? 1 : 0

  origin {
    domain_name = module.s3_bucket.s3_bucket_bucket_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.access_control_origin.id
    origin_id                = "${local.master_dns_record} distribution id"
    origin_path              = "" 
  }
  
  enabled             = true
  comment             = "${local.features_dns_record} features"

  aliases = ["${local.features_dns_record}.${var.config.hostedZone}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.master_dns_record} distribution id"

    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.features_redirect[0].arn
    }
  }

  price_class = "PriceClass_100"

  custom_error_response {
    error_caching_min_ttl = 300
    error_code            = 403
    response_code         = 200
    response_page_path    = "/master/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.features_certificate[0].arn
    
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = var.tags
}

# Create cloudfront distribution for master feature
resource "aws_cloudfront_distribution" "zone_apex_distribution" {
  count = var.env != "prod" ? 0 : 1 # only for prod

  origin {
    domain_name              = module.s3_bucket.s3_bucket_bucket_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.access_control_origin.id
    origin_id                = "${local.master_dns_record} distribution id"
    origin_path              = "/master" 
  }
  
  enabled             = true
  comment             = "${local.master_dns_record} zone apex distribution"
  default_root_object = "index.html"

  aliases = [var.config.hostedZone]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.master_dns_record} distribution id"

    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  custom_error_response {
    error_caching_min_ttl = 300
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_caching_min_ttl = 300
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.zone_apex_certificate[0].arn
    
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = var.tags
}

# create distribution alias record for master feature
resource "aws_route53_record" "distribution_alias_record" {
  zone_id = data.aws_route53_zone.primary.id
  name    = local.master_dns_record
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.master_feature_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.master_feature_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# create distribution alias record for zone apex
resource "aws_route53_record" "zone_apex_alias_record" {
  count = var.env != "prod" ? 0 : 1

  zone_id = data.aws_route53_zone.primary.id
  name    = ""
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.zone_apex_distribution[0].domain_name
    zone_id                = aws_cloudfront_distribution.zone_apex_distribution[0].hosted_zone_id
    evaluate_target_health = false
  }
}

# create distribution alias record for featurs
resource "aws_route53_record" "distribution_features_alias_record" {
  count = var.env != "prod" ? 1 : 0

  zone_id = data.aws_route53_zone.primary.id
  name    = local.features_dns_record
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.features_distribution[0].domain_name
    zone_id                = aws_cloudfront_distribution.features_distribution[0].hosted_zone_id
    evaluate_target_health = false
  }
}

# Attach policy to S3 bucket in order to allow distributions to get objects from it
resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = module.s3_bucket.s3_bucket_id
  policy = data.aws_iam_policy_document.allow_access_from_cloudfront_distribution.json
}

# Create bucket policy for allowind cloudfront distributions to get objects from bucket
data "aws_iam_policy_document" "allow_access_from_cloudfront_distribution" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]

    resources = ["${module.s3_bucket.s3_bucket_arn}/*"]

    condition {
      test     = "StringLike"
      variable = "AWS:SourceArn"
      values   = var.env != "prod" ? [
        aws_cloudfront_distribution.master_feature_distribution.arn,
        aws_cloudfront_distribution.features_distribution[0].arn
      ] : [
         aws_cloudfront_distribution.master_feature_distribution.arn,
         aws_cloudfront_distribution.zone_apex_distribution[0].arn
      ]
    }
  }
}

resource "aws_cloudfront_function" "features_redirect" {
  count = var.env != "prod" ? 1 : 0

  name    = "${var.env}-${var.config.subdomain}-features-redirect"
  runtime = "cloudfront-js-1.0"
  comment = "Routes to s3 folder where ui build is uploaded by subdomain name"
  publish = true
  code    = <<-EOF
function handler(event) {
    var request = event.request;
    var headers = request.headers;
    var host = headers.host.value; // get host
    
    var subdomain = host.split('.')[0];
    
    request.uri = '/' + subdomain + request.uri;

    if (request.uri.endsWith('/')) {
        request.uri += 'index.html';
     }

     if(!/\.[0-9a-z]+$/i.test(request.uri)) {
        request.uri = '/' + subdomain + '/index.html';
     }
      
    return request;
}
EOF
}
