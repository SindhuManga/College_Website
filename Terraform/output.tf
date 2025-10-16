output "instance_public_ip" {
  description = "Public IP address of the EC2 instance to access the website."
  value       = aws_instance.demo.public_ip
}

output "ssh_command" {
  description = "Example command to SSH into the instance (use the ec2-user username)."
  value       = "ssh -i your-key.pem ec2-user@${aws_instance.demo.public_ip}"
}

output "security_group_id" {
  description = "The ID of the Security Group allowing web access."
  value       = aws_security_group.web_sg.id
}