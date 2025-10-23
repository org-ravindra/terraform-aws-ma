variable "vpc_id" {}
variable "alb_sg_id" {}

resource "aws_security_group" "app" {
  name        = "ma-app-sg"
  description = "Allow ALB -> app:8080"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
    description     = "From ALB only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ma-app-sg" }
}

output "app_sg_id" { value = aws_security_group.app.id }
