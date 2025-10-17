provider "aws" {
  region = "eu-north-1"
}

# Security Group
resource "aws_security_group" "web_sg" {
  name        = "terraform-web-sg"
  description = "Allow HTTP traffic"
  vpc_id      = var.vpc_id  # Replace with your VPC ID

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Terraform-Web-SG"
  }
}

# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "Terraform-EC2-Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2_policy_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "ecr_policy_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "Terraform-Instance-Profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 Instance
resource "aws_instance" "docker_host" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true   # ✅ Important!

  tags = {
    Name = "Terraform-EC2-Docker-Host"
  }

  user_data = <<-EOT
    #!/bin/bash
    sudo yum update -y
    sudo amazon-linux-extras install docker -y
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -a -G docker ec2-user

    # Login to ECR
    aws ecr get-login-password --region eu-north-1 | docker login --username AWS --password-stdin 944731154859.dkr.ecr.eu-north-1.amazonaws.com/ecr-repo

    # Pull and run Docker image
    docker pull 944731154859.dkr.ecr.eu-north-1.amazonaws.com/ecr-repo:latest
    docker run -d -p 80:80 944731154859.dkr.ecr.eu-north-1.amazonaws.com/ecr-repo:latest
  EOT
}


