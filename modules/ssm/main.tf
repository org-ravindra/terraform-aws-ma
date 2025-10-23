variable "parameters" { type = map(string) }

resource "aws_ssm_parameter" "params" {
  for_each  = var.parameters
  name      = "/ma/${each.key}"
  type      = "SecureString"
  value     = each.value
  overwrite = true
}
