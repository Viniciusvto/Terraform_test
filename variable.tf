variable "instance_name" {
  description = "Nome da instância EC2"
  type        = string
  default     = "teko-api"
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t3.micro"
}

variable "meu_ip" {
  description = "IP público da minha casa, liberado no Security Group"
  type        = string
}

variable "caminho_chave_publica" {
  description = "Chave pública SSH registrada na AWS"
  type        = string
  default     = "~/.ssh/teko-ec2.pub"
}
