resource "aws_ssm_parameter" "config" {
  name  = "/${var.env}/${var.config.subdomain}"
  type  = "String"
  value = "${var.config.subdomain}${var.env != "prod" ? ".${var.env}" : ""}.${var.config.hostedZone}"

  tags = var.tags
}