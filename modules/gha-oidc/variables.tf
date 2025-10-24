variable "provider_url" {
    description = "OIDC provider URL for GitHub Actions. For github.com use https://token.actions.githubusercontent.com"
    type        = string
    default     = "https://token.actions.githubusercontent.com"
}

variable "audiences" {
    description = "Allowed OIDC audiences. For AWS STS use [\"sts.amazonaws.com\"]."
    type        = list(string)
    default     = ["sts.amazonaws.com"]
}

variable "thumbprints" {
    description = "Optional explicit thumbprints for the OIDC provider. Defaults to known GitHub OIDC root CA thumbprints."
    type        = list(string)
    default     = []
}

variable "github_owner" {
    description = "GitHub organization or user that owns the repository (e.g., 'ravindrabajpai')."
    type        = string
}

variable "github_repo" {
    description = "Repository name (e.g., 'terraform-aws-ma')."
    type        = string
}

variable "allowed_branches" {
    description = "List of branch names (without refs/heads/) allowed to assume the role."
    type        = list(string)
    default     = ["main"]
}

variable "allowed_tags" {
    description = "Optional list of tag patterns allowed to assume the role (values become refs/tags/<tag>). Supports wildcards."
    type        = list(string)
    default     = []
}

variable "allowed_environments" {
    description = "Optional list of GitHub Environments allowed to assume the role (uses sub = repo:<org>/<repo>:environment:<env>)."
    type        = list(string)
    default     = []
}

variable "allow_pull_request" {
    description = "Whether to allow GitHub pull_request jobs to assume the role."
    type        = bool
    default     = true
}

variable "role_name" {
    description = "Name of the IAM role to create for GitHub Actions (e.g., 'ma-tf-gha-role')."
    type        = string
    default     = "ma-tf-gha-role"
}

variable "role_description" {
    description = "Optional description for the IAM role."
    type        = string
    default     = "GitHub Actions OIDC role for Terraform deploys"
}

variable "permissions_policy_arns" {
    description = "List of AWS managed or customer-managed policy ARNs to attach to the role. Keep least-privilege."
    type        = list(string)
    default     = [
        # For initial bootstrap you may use AdministratorAccess, then replace with scoped policies.
        # "arn:aws:iam::aws:policy/AdministratorAccess"
    ]
}

variable "inline_policy_json" {
    description = "Optional raw JSON for an inline policy attached to the role (use for small, scoped permissions)."
    type        = string
    default     = null
}

variable "inline_policy_name" {
    description = "Name for the optional inline policy if provided."
    type        = string
    default     = "gha-inline-policy"
}

variable "tags" {
    description = "Optional tags to apply to created resources."
    type        = map(string)
    default     = {}
}
