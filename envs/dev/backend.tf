terraform {
  backend "s3" {
    bucket         = "ma-tfstate-bucket"
    key            = "envs/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ma-tfstate-locks"
    encrypt        = true
  }
  required_version = ">= 1.6.0"
}
