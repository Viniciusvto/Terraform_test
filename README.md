# Provisionamento de Infraestrutura AWS com Terraform (Tekó API)

Este repositório contém os scripts de **Infraestrutura como Código (IaC)** utilizando **Terraform** para provisionar automaticamente um servidor na AWS (Amazon EC2) configurado com Ubuntu e suporte a Docker.

---

## 📁 Estrutura do Projeto

```text
.
├── main.tf              # Configuração principal dos recursos AWS
├── variable.tf          # Declaração e tipos das variáveis
├── terraform.tfvars     # Valores específicos das variáveis (como meu IP)
├── outputs.tf           # Saídas exibidas após o término da execução
├── terraform.tf         # Provedores e versões requeridas do Terraform
├── user_data.sh         # Script Shell executado no boot da VM
└── README.md            # Documentação do projeto

