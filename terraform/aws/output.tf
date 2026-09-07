output "public_ip" {
  description = "Public IP — paste this into inventory.ini"
  value       = aws_instance.epicbook.public_ip
}

output "admin_user" {
  description = "SSH username for Ubuntu AMIs"
  value       = "ubuntu"
}