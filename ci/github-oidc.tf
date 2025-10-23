terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_openid_connect_provider" "gh" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "gh_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals { type = "Federated" identifiers = [aws_iam_openid_connect_provider.gh.arn] }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:ravindrabajpai/terraform-aws-ma:*"]
    }
  }
}

resource "aws_iam_role" "tf_deploy" {
  name               = "ma-tf-gha-role"
  assume_role_policy = data.aws_iam_policy_document.gh_assume.json
}

# NOTE: For production, scope this down; using Admin for simplicity in Phase A.
resource "aws_iam_role_policy_attachment" "tf_admin" {
  role       = aws_iam_role.tf_deploy.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "gha_role_arn" {
  value = aws_iam_role.tf_deploy.arn
  description = "Use this ARN in GitHub Actions 'role-to-assume'"
}
