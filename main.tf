# Get latest Amazon Linux 2 AMI
data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Get Ubuntu 22.04 LTS (Jammy) AMI for the region
data "aws_ami" "ubuntu2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Key pair from your public key file
resource "aws_key_pair" "deployer" {
  key_name   = "ci-deployer-key"
  public_key = file(var.ssh_public_key_path)
}

# Security group: allow SSH, HTTP(80) and Netdata(19999)
resource "aws_security_group" "vm_sg" {
  name        = "ci-vm-sg"
  description = "Allow SSH, HTTP, Netdata"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Netdata"
    from_port   = 19999
    to_port     = 19999
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Data source: get default VPC (for simple demo)
data "aws_vpc" "default" {
  default = true
}
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

# Amazon Linux VM (frontend) - c8.local
resource "aws_instance" "c8" {
  ami                    = data.aws_ami.amzn2.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.vm_sg.id]
  subnet_id              = data.aws_subnet_ids.default.ids[0]
  tags = {
    Name = "c8.local"
  }
  user_data = <<-EOF
              #!/bin/bash
              hostnamectl set-hostname c8.local
              EOF
}

# Ubuntu VM (backend) - u21.local (I'll create using 22.04 jammy example)
resource "aws_instance" "u21" {
  ami                    = data.aws_ami.ubuntu2204.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.vm_sg.id]
  subnet_id              = data.aws_subnet_ids.default.ids[0]
  tags = {
    Name = "u21.local"
  }
  user_data = <<-EOF
              #cloud-config
              hostname: u21.local
              fqdn: u21.local
              EOF
}

# Template rendering to create ansible inventory file dynamically
data "template_file" "inventory" {
  template = file("${path.module}/inventory.tpl")
  vars = {
    c8_public_ip     = aws_instance.c8.public_ip
    c8_private_ip    = aws_instance.c8.private_ip
    u21_public_ip    = aws_instance.u21.public_ip
    u21_private_ip   = aws_instance.u21.private_ip
    private_key_path = var.private_key_path
  }
}

resource "local_file" "ansible_inventory" {
  content  = data.template_file.inventory.rendered
  filename = "${path.module}/../ansible/inventory.ini"
}
