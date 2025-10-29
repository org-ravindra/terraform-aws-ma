variable "region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type for the app host"
  type        = string
  default     = "t4g.small"
}

variable "github_token" {
  description = "GitHub PAT (optional) to improve clone/rate limits"
  type        = string
  sensitive   = true
  validation {
    condition     = length(trimspace(var.github_token)) > 0
    error_message = "github_token must be non-empty."
  }
}

variable "ma_admin_token" {
  description = "Admin token for MA"
  type        = string
  sensitive   = true

  validation {
    condition     = length(trimspace(var.ma_admin_token)) > 0
    error_message = "ma_admin_token must be non-empty."
  }
}

variable "create" {
  type    = bool
  default = true
}