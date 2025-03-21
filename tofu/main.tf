terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "windows" {
  key_name   = "mar25-windows-key"
  public_key = file(var.public_key_path)
}
resource "aws_instance" "windows_server" {
  ami           = data.aws_ami.windows.id
  instance_type = var.instance_type

  key_name = aws_key_pair.windows.key_name

  vpc_security_group_ids = [aws_security_group.allow_iis_winrm_rdp.id]

  tags = {
    Name = "mar-25-windows"
  }

  # Login med lösenord kräver att vi använder administrator password
  get_password_data = true
}

resource "aws_security_group" "allow_iis_winrm_rdp" {
  name        = "allow-iis-winrm-rdp"
  description = "Allow HTTP (80), RDP (3389), WinRM (5985)"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "RDP from own computer"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["${var.laptop_ip}/32"]
  }

  ingress {
    description = "WinRM from CloudShell"
    from_port   = 5985
    to_port     = 5985
    protocol    = "tcp"
    cidr_blocks = ["${var.cloudshell_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
