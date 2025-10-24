output "oidc_provider_arn" {
    description = "ARN of the GitHub OIDC provider"
    value       = aws_iam_openid_connect_provider.github.arn
}

output "role_arn" {
    description = "ARN of the GitHub Actions IAM role"
    value       = aws_iam_role.gha_role.arn
}

output "role_name" {
    description = "Name of the GitHub Actions IAM role"
    value       = aws_iam_role.gha_role.name
}