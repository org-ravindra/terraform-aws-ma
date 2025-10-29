variable "name" {}
variable "vpc_id" {}
variable "public_subnet_ids" { type = list(string) }
variable "target_port" {}

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "ALB SG"
  vpc_id      = var.vpc_id
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"] # optional
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name    = "${var.name}-alb-sg"
    Project = "ma"
    Env     = "dev"
  }
}

resource "aws_lb" "this" {
  name               = "ma-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name    = "${var.name}-alb"
    Project = "ma"
    Env     = "dev"
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "${var.name}-tg"
  port     = var.target_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path    = "/health"
    matcher = "200-399"
  }
  tags = {
    Name    = "${var.name}-tg"
    Project = "ma"
    Env     = "dev"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

output "tg_arn"    { value = aws_lb_target_group.tg.arn }
output "alb_dns"   { value = aws_lb.this.dns_name }
output "alb_sg_id" { value = aws_security_group.alb.id }
