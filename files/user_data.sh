#!/usr/bin/env bash
set -eux

# Install docker and compose plugin (Amazon Linux 2023 / RHEL-family)
dnf update -y
dnf install -y docker docker-compose-plugin socat jq

systemctl enable docker
systemctl start docker

# Create working dir
mkdir -p /opt/ma

# Region comes from Terraform templatefile variable injection
REGION="${REGION}"

GH_PARAM="/ma/MA_GITHUB_TOKEN"
ADMIN_PARAM="/ma/MA_ADMIN_TOKEN"

# Ensure AWS CLI exists (AL2023 usually has it; keep this resilient)
if ! command -v aws >/dev/null 2>&1; then
  dnf install -y awscli
fi

# Pull secrets from SSM (ignore if not present)
aws ssm get-parameter --name "$GH_PARAM" --with-decryption --region "$REGION" \
  --query "Parameter.Value" --output text > /opt/ma/github_token || true

aws ssm get-parameter --name "$ADMIN_PARAM" --with-decryption --region "$REGION" \
  --query "Parameter.Value" --output text > /opt/ma/admin_token || true

# Start stack (expects /opt/ma/docker-compose.yml to be provisioned separately)
docker compose -f /opt/ma/docker-compose.yml up -d || true

# Simple TCP proxy for ALB health on 8080 -> UI 8501
cat >/etc/systemd/system/health-proxy.service <<'SVC'
[Unit]
Description=Proxy 8080 -> 8501 for ALB health
After=docker.service
[Service]
Type=simple
ExecStart=/usr/bin/socat TCP-LISTEN:8080,fork,reuseaddr TCP:127.0.0.1:8501
Restart=always
[Install]
WantedBy=multi-user.target
SVC

systemctl daemon-reload
systemctl enable --now health-proxy
