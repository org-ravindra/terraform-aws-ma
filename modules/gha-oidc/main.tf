terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = ">= 5.0"
        }
    }
}

locals {
    # Build the set of allowed subjects for this role
    branch_subjects = [for b in var.allowed_branches : "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${b}"]
    tag_subjects     = [for t in var.allowed_tags : "repo:${var.github_owner}/${var.github_repo}:ref:refs/tags/${t}"]
    pr_subjects      = var.allow_pull_request ? ["repo:${var.github_owner}/${var.github_repo}:pull_request"] : []
    env_subjects     = [for e in var.allowed_environments : "repo:${var.github_owner}/${var.github_repo}:environment:${e}"]
    all_subjects     = distinct(concat(local.branch_subjects, local.tag_subjects, local.pr_subjects, local.env_subjects))

    # Back-compat: keep a stable name for the OIDC provider
    oidc_thumbprints = length(var.thumbprints) > 0 ? var.thumbprints : [
        # GitHub Actions OIDC currently uses these root CAs. Keep configurable.
        # - DigiCert High Assurance EV Root CA: 6938fd4d98bab03faadb97b34396831e3780aea1
        # - DigiCert Global Root CA (as rotated by GitHub): 1c58a3a8511e6b2a39b5790c1d7687f5df91995b
        "6938fd4d98bab03faadb97b34396831e3780aea1",
        "1c58a3a8511e6b2a39b5790c1d7687f5df91995b"
    ]

    branch_subscription = local.branch_subjects
}

resource "aws_iam_openid_connect_provider" "github" {
    url             = var.provider_url
    client_id_list  = var.audiences
    thumbprint_list = local.oidc_thumbprints

    tags = merge({
        "Name"        : "github-oidc-provider",
        "Provisioner" : "terraform",
    }, var.tags)
}

# Trust policy for GitHub OIDC
data "aws_iam_policy_document" "gha_trust" {
    statement {
        sid    = "GitHubActionsOpenIDConnectTrust"
        effect = "Allow"

        principals {
            type       = "Federated"
            identifiers = [aws_iam_openid_connect_provider.github.arn]
        }

        actions = [
            "sts:AssumeRoleWithWebIdentity"
        ]

        condition {
            test     = "StringEquals"
            variable = "token.actions\.githubusercontent\.com:aud"
            values   = var.audiences
        }

        # Limit which GitHub workflows can assume the role via the `sub` claim
        condition {
            test     = "StringLike"
            variable = "token.actions\.githubusercontent\.com:sub"
            values   = local.all_subjects
        }
    }
}

resource "aws_iam_role" "gha_role" {
    name                = var.role_name
    description         = var.role_description
    assume_role_policy  = data.aws_iam_policy_document.gha_trust.json

    tags = merge({
        "Name"        : var.role_name,
        "Provisioner" : "terraform",
    }, var.tags)
}

# Optional: attach one or more managed policies (e.g., AdministratorAccess during bootstrap,
# then replace with scoped least-privilege policies once your Terraform state is in place).
resource "aws_iam_role_policy_attachment" "managed" {
    for_each   = toset(var.permissions_policy_arns)
    role       = aws_iam_role.gha_role.name
    policy_arn = each.value
}

# Optional: inline policy for quick starts or very targeted permissions
resource "aws_iam_role_policy" "inline" {
    count  = var.inline_policy_json == null ? 0 : 1
    name   = var.inline_policy_name
    role   = aws_iam_role.gha_role.id
    policy = var.inline_policy_json
}
