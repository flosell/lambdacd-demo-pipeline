provider "aws" {
  region = "${var.aws_region}"
}

data "aws_ami" "amazon_linux" {
  most_recent      = true

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*"]
  }

  owners = ["amazon"]
}
