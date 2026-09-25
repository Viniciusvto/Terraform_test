output "instance_hostname" {
    description = "Private DNS hostname of the instance"
    value       = aws_instance.app_server.private_dns
}
