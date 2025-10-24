provider "aws" {
  region = var.region
}

module "vpc" {
  source     = "../../modules/vpc"
  name       = "ma"
  cidr_block = "10.20.0.0/16"
  az_count   = 2
}

module "gha_oidc" {
  source                = "./modules/gha-oidc"
  github_owner          = "ravindrabajpai"
  github_repo           = "terraform-aws-ma"
  allowed_branches      = ["main"]
  allow_pull_request    = true
  permissions_policy_arns = [
    # For initial bootstrap only; replace with least-privilege policies once your stacks exist
    # "arn:aws:iam::aws:policy/AdministratorAccess"
  ]
  tags = {
    Project = "terraform-aws-ma"
    Env     = "dev"
  }
}

module "alb" {
  source            = "../../modules/alb"
  name              = "ma"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  target_port       = 8080
}

module "security" {
  source     = "../../modules/security"
  vpc_id     = module.vpc.vpc_id
  alb_sg_id  = module.alb.alb_sg_id
}

module "ssm" {
  source = "../../modules/ssm"
  parameters = {
    "MA_GITHUB_TOKEN" = var.github_token
    "MA_ADMIN_TOKEN"  = var.ma_admin_token
  }
}

module "ec2_app" {
  source        = "../../modules/ec2_app"
  name          = "ma"
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.public_subnet_ids[0]
  sg_ids        = [module.security.app_sg_id]
  alb_tg_arn    = module.alb.tg_arn
  instance_type = var.instance_type
  arch          = "arm64" # switch to "x86_64" if using t3.*
  user_data     = templatefile("../../files/user_data.sh", { REGION = var.region })
  files_to_push = {
    "/opt/ma/docker-compose.yml" = file("../../files/docker-compose.yml")
  }
  tags = { Project = "MA", Env = "dev" }
}
