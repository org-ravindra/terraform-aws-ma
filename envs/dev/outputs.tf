output "alb_dns" {
  description = "Public DNS of the Application Load Balancer"
  value       = module.alb.alb_dns
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
