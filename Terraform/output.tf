# Outputs
output "instance_id" {
  value = aws_instance.docker_host.id
}

output "instance_public_ip" {
  value = aws_instance.docker_host.public_ip
}

output "security_group_id" {
  value = aws_security_group.web_sg.id
}

output "iam_role_name" {
  value = aws_iam_role.ec2_role.name
}