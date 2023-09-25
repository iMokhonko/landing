resource "aws_ssm_parameter" "this" {
  name  = "/${var.env}/${var.dns_service_name}"
  type  = "String"
  value = var.dns_address

  tags = {
    Env = var.env
  }
}