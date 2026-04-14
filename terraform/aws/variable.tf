variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Used as a prefix on all resource names"
  type        = string
  default     = "epicbook"
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI — update if your region differs"
  type        = string
  default     = "ami-0c7217cdde317cfec"  # us-east-1 Ubuntu 22.04
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "public_key_path" {
  description = "Path to your SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}