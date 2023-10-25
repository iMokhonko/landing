resource "aws_ssm_parameter" "foo" {
  name  = "/${var.env}/${var.config.subdomain}"
  type  = "String"
  value = var.context.dns.dns_address

  tags = var.tags
}