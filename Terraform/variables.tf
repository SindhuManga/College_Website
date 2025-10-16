# AWS Provider Variables
variable "aws_region" {
  description = "The AWS region to deploy resources into."
  type        = string
  default     = "eu-north-1"
}

# EC2 Instance Variables
variable "instance_ami" {
  description = "The AMI ID for the EC2 instance (Amazon Linux 2 in eu-north-1)."
  type        = string
  default     = "ami-04c08fd8aa14af291"
}

variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "instance_name" {
  description = "The Name tag for the EC2 instance."
  type        = string
  default     = "Terraform-ec2-docker-host"
}

variable "key_pair_name" {
  description = "The name of the Key Pair to associate with the EC2 instance for SSH access. (REQUIRED)"
  type        = string
  # No default, as a key pair is specific and required for access.
}

# Docker/ECR Deployment Variables
variable "ecr_repository_url" {
  description = "The full URL of the ECR repository for the college-website image."
  type        = string
  default     = "944731154859.dkr.ecr.eu-north-1.amazonaws.com/ecr-repo"
}

variable "ecr_image_tag" {
  description = "The tag of the Docker image to pull from ECR."
  type        = string
  default     = "latest"
}

variable "iam_instance_profile_name" {
  description = "The name of the IAM Instance Profile (Role) with ECR Read-Only permissions."
  type        = string
  # No default, as this is a crucial security component you must provision.
}