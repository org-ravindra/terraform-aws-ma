# terraform-aws-ma

Infrastructure-as-code for a **minimal-cost** AWS deployment of the *Master Architect (MA)* app using Terraform + GitHub Actions (OIDC).

**Phase A (this repo):**
- VPC with **public subnets** (no NAT to keep costs low).
- **Application Load Balancer (HTTP:80)** in public subnets.
- **One EC2 (Amazon Linux 2023)** in a public subnet, managed by **SSM** (no SSH).
- EC2 runs a **Docker Compose** stack:
  - `pgvector` (Postgres+pgvector),
  - `redis` (RQ),
  - `ollama` (Llama 3.1 8B, pulled on boot),
  - `api` and `worker` (placeholders; replace with your images),
  - `ui` (placeholder; replace with your image).
- **SSM Parameter Store** for secrets (`/ma/MA_GITHUB_TOKEN`, `/ma/MA_ADMIN_TOKEN`).
- **Terraform state**: S3 backend + DynamoDB lock (create once).
- **GitHub OIDC** role for CI/CD (plan/apply/destroy).

> This is a starter footprint designed to be cheap and simple. Later you can swap Postgres -> RDS, move services to ECS/EKS, add HTTPS/ACM, etc.

---

## 1) One-time: Create Terraform backend (S3 + DynamoDB)

```bash
aws s3api create-bucket --bucket ma-tfstate-bkt --region us-east-1
aws dynamodb create-table --table-name ma-tfstate-locks   --attribute-definitions AttributeName=LockID,AttributeType=S   --key-schema AttributeName=LockID,KeyType=HASH   --billing-mode PAY_PER_REQUEST
```

If you prefer a different bucket/table/region, edit `envs/dev/backend.tf`.

---

## 2) One-time: Configure GitHub OIDC role in your AWS account

Edit `ci/github-oidc.tf` and replace:
- `${{ vars.AWS_ACCOUNT_ID }}` → your 12-digit AWS account ID.

The GitHub org/user is already set to `ravindrabajpai` and repo filter `repo:ravindrabajpai/terraform-aws-ma:*`.

Then apply:
```bash
cd ci
terraform init
terraform apply -auto-approve
```

This will output `gha_role_arn`; copy it for the GitHub Actions workflows.

---

## 3) Repo secrets (on GitHub → Settings → Secrets and variables → Actions → New repository secret)

- `MA_GITHUB_TOKEN` → (optional) Personal Access Token for higher GitHub clone rate limits. Leave blank to use anonymous.
- `MA_ADMIN_TOKEN` → any random string (used by the MA API).

---

## 4) Deploy the environment

```bash
cd envs/dev
terraform init
terraform apply -auto-approve   -var='region=us-east-1'   -var='instance_type=t4g.small'   -var='github_token=${MA_GITHUB_TOKEN:-}'   -var='ma_admin_token=YOUR_RANDOM_TOKEN'
```

> If you don’t have Graviton (ARM) quotas, switch to `-var='instance_type=t3.small'` and in `envs/dev/main.tf` change `arch = "x86_64"`.

When apply completes, note the `alb_dns` output (e.g., `ma-alb-...elb.amazonaws.com`). Open it in a browser.

---

## 5) GitHub Actions (CI/CD)

`plan.yml`, `apply.yml`, and `destroy.yml` are included.  
**Edit** the `role-to-assume` account ID to your real AWS account in those workflows.

---

## Layout

```
terraform-aws-ma/
  modules/
    vpc/
    alb/
    security/
    ssm/
    ec2_app/
  envs/
    dev/
      backend.tf
      main.tf
      variables.tf
      outputs.tf
  ci/
    github-oidc.tf
  files/
    user_data.sh
    docker-compose.yml
  .github/workflows/
    plan.yml
    apply.yml
    destroy.yml
  README.md
  LICENSE
  .gitignore
```

---

## Notes

- EC2 is in a **public subnet** for simplicity (so Docker can pull images). In prod, move to private subnets with NAT/ECR/VPC endpoints.
- ALB is **HTTP-only** to save cost/steps. Add ACM + HTTPS listener later.
- The `health-proxy` systemd service maps ALB port 8080 → UI 8501.
- Replace `ghcr.io/yourorg/...` images with your own once the MA app containers are built.
