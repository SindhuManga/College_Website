variable "key_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
  default     = "My_Key_Pair"  # Replace with your key pair
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
