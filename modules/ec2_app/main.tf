variable "name" {}
variable "vpc_id" {}
variable "subnet_id" {}
variable "sg_ids" { type = list(string) }
variable "alb_tg_arn" {}
variable "instance_type" { default = "t4g.small" }
variable "arch" { default = "arm64" }
variable "user_data" { type = string }
variable "files_to_push" { type = map(string) }
variable "tags" { type = map(string) }

data "aws_iam_policy_document" "assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


resource "aws_iam_role" "role" {
  name               = "${var.name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cw" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "s3read" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "profile" {
  name = "${var.name}-ec2-profile"
  role = aws_iam_role.role.name
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-${var.arch}*"]
  }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.sg_ids
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.profile.name
  user_data                   = var.user_data
  metadata_options { http_tokens = "required" }
  root_block_device { volume_size = 60 volume_type = "gp3" }
  tags = merge({ Name = "${var.name}-app" }, var.tags)
}

resource "aws_lb_target_group_attachment" "attach" {
  target_group_arn = var.alb_tg_arn
  target_id        = aws_instance.app.id
  port             = 8080
}

resource "aws_ssm_document" "push_files" {
  name          = "${var.name}-push-files"
  document_type = "Command"
  content = jsonencode({
    schemaVersion = "2.2",
    description   = "Push files to instance",
    mainSteps = [{
      action = "aws:runShellScript",
      name   = "writefiles",
      inputs = {
        runCommand = [
          for path, content in var.files_to_push :
          "cat > ${path} <<'EOF'\n${content}\nEOF\n"
        ]
      }
    }]
  })
}

resource "aws_ssm_association" "push_files" {
  name   = aws_ssm_document.push_files.name
  targets = [{ key = "InstanceIds", values = [aws_instance.app.id] }]
  wait_for_success_timeout_seconds = 300
}
