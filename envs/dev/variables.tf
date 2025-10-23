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
  default     = ""
}

variable "ma_admin_token" {
  description = "Admin token for MA API"
  type        = string
  sensitive   = true
}
