# För att sätta dina egna värden och slippa skriva in dem varje körning
# skapa en fil som heter terraform.tfvars
#  referens: https://developer.hashicorp.com/terraform/tutorials/configuration-language/variables#assign-values-with-a-file

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "Typ av EC2-instans"
  type        = string
  default     = "t3.micro"
}

variable "public_key_path" {
  description = "Sökväg till den publika delen av (<filnamn>.pub) din RSA nyckel"
  type        = string
  default     = "~/.ssh/windows-key.pem.pub"
}

variable "cloudshell_ip" {
  description = "IP-adress till Cloudshell"
  type        = string
}

variable "laptop_ip" {
  description = "IP-adress till din egen privata laptop"
  type        = string
}

