variable "parameters" { type = map(string) }

locals {
  non_empty_params = {
    for k, v in var.parameters :
    k => v if length(trimspace(v)) > 0
  }
}

resource "aws_ssm_parameter" "params" {
  for_each  = local.non_empty_params
  name      = "/ma/${each.key}"
  type      = "SecureString"
  value     = each.value
  overwrite = true
}
