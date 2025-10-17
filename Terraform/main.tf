provider "aws" {
  region = var.region
}

# IAM Role for EC2 (with EC2 + ECR permissions)
resource "aws_iam_role" "ec2_role" {
  name = "Terraform-EC2-Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
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

# Security Group
resource "aws_security_group" "web_sg" {
  name        = "web_server_sg"
  description = "Allow HTTP and SSH traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
}

# Latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# EC2 Instance with systemd service for Docker container
resource "aws_instance" "docker_host" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "Terraform-ec2-docker-host"
  }

  user_data = <<-EOT
    #!/bin/bash
    sudo yum update -y
    sudo amazon-linux-extras install docker -y
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -a -G docker ec2-user
    sleep 15

    sudo tee /etc/systemd/system/college-website.service > /dev/null <<EOF
    [Unit]
    Description=College Website Docker Container
    After=docker.service
    Requires=docker.service

    [Service]
    Type=simple
    Restart=always
    ExecStart=/bin/bash -c '
      aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${var.ecr_repo}
      docker pull ${var.ecr_repo}:latest
      docker run -d -p 80:80 ${var.ecr_repo}:latest
    '
    ExecStop=/usr/bin/docker stop $(/usr/bin/docker ps -q --filter ancestor=${var.ecr_repo}:latest)

    [Install]
    WantedBy=multi-user.target
    EOF

    sudo systemctl daemon-reload
    sudo systemctl enable college-website.service
    sudo systemctl start college-website.service
  EOT
}
