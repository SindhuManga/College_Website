# Use the declared region variable
provider "aws" {
  region = var.aws_region
}

# 1. Define a Security Group to allow SSH (22) and HTTP (80)
resource "aws_security_group" "web_sg" {
  name        = "web_server_sg-${var.instance_name}"
  description = "Allow HTTP and SSH inbound traffic"
  
  # Ingress rule for HTTP (Web Access)
  ingress {
    description = "HTTP access from world"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Ingress rule for SSH (Admin Access)
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule (Allow all outbound traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. EC2 Instance with User Data to install Docker and run the container
resource "aws_instance" "demo" {
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  
  # Attach the IAM Instance Profile (Crucial for ECR login)
  iam_instance_profile   = var.iam_instance_profile_name

  tags = {
    Name = var.instance_name
  }

  # User Data script for automated deployment
  user_data = <<-EOF
              #!/bin/bash
              # Update system and install Docker and AWS CLI (if not pre-installed)
              sudo yum update -y
              sudo yum install docker -y
              
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo usermod -a -G docker ec2-user
              
              # Construct full image URL
              FULL_IMAGE_URL="${var.ecr_repository_url}:${var.ecr_image_tag}"
              
              # Retrieve ECR credentials and login
              # The AWS CLI must be installed on the AMI (it is on Amazon Linux 2)
              aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.ecr_repository_url}
              
              # Pull and run the container
              docker run -d -p 80:80 $FULL_IMAGE_URL
              EOF
}