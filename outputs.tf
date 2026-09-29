output "ip_publico" {
  description = "IP público da instância"
  value       = aws_instance.app_server.public_ip
}

output "comando_ssh" {
  description = "Comando para entrar na instância"
  value       = "ssh -i ~/.ssh/teko-ec2 ubuntu@${aws_instance.app_server.public_ip}"
}

output "url_api" {
  description = "Endereço da API do Tekó"
  value       = "http://${aws_instance.app_server.public_ip}:3000"
}
