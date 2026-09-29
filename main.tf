provider "aws" {
  region = "us-east-1"
}

# Imagem do sistema: Ubuntu 24.04 LTS oficial da Canonical
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

# Registra a chave publica na AWS
resource "aws_key_pair" "teko" {
  key_name   = "teko-ec2"
  public_key = file(pathexpand(var.caminho_chave_publica))
}

# Firewall da instancia
resource "aws_security_group" "teko" {
  name        = "teko-api"
  description = "SSH e API do Teko liberados so para o meu IP"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.meu_ip}/32"]
  }

  ingress {
    description = "API do Teko"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["${var.meu_ip}/32"]
  }

  egress {
    description = "Saida liberada"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.teko.key_name
  vpc_security_group_ids      = [aws_security_group.teko.id]
  associate_public_ip_address = true
  user_data                   = file("${path.module}/user_data.sh")

  tags = {
    Name = var.instance_name
  }

  lifecycle {
    ignore_changes = [ami]
  }
}
