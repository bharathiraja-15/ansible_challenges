variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/ci_deploy_key.pub"
}

variable "private_key_path" {
  type    = string
  default = "~/.ssh/ci_deploy_key"
}
