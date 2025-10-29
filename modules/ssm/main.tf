variable "parameters" { type = map(string) }

variable "ma_admin_token" {
  type        = string
  sensitive   = true
  validation {
    condition     = length(trim(var.ma_admin_token)) > 0
    error_message = "ma_admin_token must be non-empty."
  }
}

resource "aws_ssm_parameter" "params" {
  for_each  = var.parameters
  name      = "/ma/${each.key}"
  type      = "SecureString"
  value     = each.value
  overwrite = true
}
