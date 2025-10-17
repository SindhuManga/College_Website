variable "key_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
  default     = "My_Key_Pair"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-north-1"
}

variable "ecr_repo" {
  description = "ECR repository URL"
  type        = string
  default     = "944731154859.dkr.ecr.eu-north-1.amazonaws.com/ecr-repo"
}
