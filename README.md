# Provisionamento de Infraestrutura AWS com Terraform (Tekó API)

Este repositório contém os scripts de **Infraestrutura como Código (IaC)** utilizando **Terraform** para provisionar automaticamente um servidor na AWS (Amazon EC2) com Ubuntu 24.04, Docker e Git, pronto para receber a API da Tekó.

> O código da API fica em um repositório separado. Aqui fica apenas a infraestrutura.

---

## O que é criado na AWS

| Recurso (`main.tf`) | Função |
|---|---|
| `data.aws_ami.ubuntu` | Não cria nada: só busca o ID da imagem oficial mais recente do Ubuntu 24.04 (Canonical) |
| `aws_key_pair.teko` | Registra a sua chave **pública** SSH na AWS com o nome `teko-ec2` |
| `aws_security_group.teko` | Firewall da instância: libera SSH (porta 22) e a API (porta 3000) **somente para o meu IP**; saída liberada |
| `aws_instance.app_server` | O servidor: `t3.micro` (padrão em `variable.tf`), região `us-east-1`, com IP público e o `user_data.sh` executado no primeiro boot |

---

## Estrutura do projeto

```text
.
├── main.tf               # Recursos AWS: imagem, chave SSH, firewall e instância
├── variable.tf           # Declaração das variáveis (tipo, descrição e valor padrão)
├── terraform.tfvars      # Meu IP publico
├── outputs.tf            # Valores exibidos ao final do apply (IP, comando SSH, URL da API)
├── terraform.tf          # Provider AWS e a versão fixada dele
├── .terraform.lock.hcl   # Trava as versões exatas dos providers a versionavel
├── user_data.sh          # Script executado uma única vez, no primeiro boot da instância
├── .gitignore            # Impede que chaves, state e tfvars subam para o GitHub
└── README.md
```

---

## Pré-requisitos

- **Conta AWS** com um usuário IAM que tenha permissão para criar recursos de EC2.
- **Terraform** instalado (confira com `terraform -version`).
- **Credenciais AWS configuradas** na sua máquina. O jeito mais simples é pela AWS CLI:

  ```bash
  aws configure                  # pede Access Key ID, Secret Access Key, região e formato de saída
  aws sts get-caller-identity    # se mostrar Account e UserId, as credenciais funcionam
  ```

  O Terraform lê essas credenciais sozinho. A região usada é a definida no `main.tf` (`us-east-1`).

- **Par de chaves SSH** em `~/.ssh/teko-ec2` (privada) e `~/.ssh/teko-ec2.pub` (pública).

  Só a chave **pública** é enviada para a AWS. A **privada** nunca sai da sua máquina.

---

## Passo a passo

### 1. Clonar o repositório

```bash
git clone https://github.com/Viniciusvto/terraform_test.git
cd terraform_test
```

### 2. Criar o arquivo `terraform.tfvars`

Ele não vem no clone, porque o `.gitignore` bloqueia arquivos `*.tfvars`. Descubra seu IP público:

```bash
curl ifconfig.me
```

E crie o `terraform.tfvars` na raiz do projeto:

```hcl
meu_ip = "SEU.IP.AQUI"
```

Coloque **só o IP**, sem `/32`: o `main.tf` já acrescenta o `/32`, que significa "exatamente este endereço".

> Sem esse arquivo, o `plan` e o `apply` vão pedir o valor de `var.meu_ip` no terminal.

### 3. `terraform init`

```bash
terraform init
```

Baixa o provider AWS (o plugin que sabe conversar com a API da AWS) para a pasta `.terraform/`, respeitando a versão travada no `.terraform.lock.hcl`. Rode uma vez por clone, e de novo se os providers mudarem.

### 4. `terraform fmt` e `terraform validate`

```bash
terraform fmt         # padroniza a formatação dos arquivos .tf
terraform validate    # confere sintaxe e referências, sem acessar a AWS
```

### 5. `terraform plan`

```bash
terraform plan
```

Compara o código com o que já existe (registrado no state) e mostra o que **seria** feito: `+` criar, `~` alterar, `-` destruir. Não altera nada. Na primeira execução, o esperado é `Plan: 3 to add, 0 to change, 0 to destroy`.

### 6. `terraform apply`

```bash
terraform apply
```

Mostra o plano de novo e só executa depois que você digitar `yes`. Ao final, exibe os outputs:

```text
Outputs:

comando_ssh = "ssh -i ~/.ssh/teko-ec2 ubuntu@<ip_publico>"
ip_publico = "<ip_publico>"
url_api = "http://<ip_publico>:3000"
```

Para ver os outputs de novo a qualquer momento: `terraform output`.

### 7. Acessar a instância via SSH

O IP público muda **a cada nova instância**, então não use um IP fixo: pegue o comando pronto do output.

```bash
terraform output -raw comando_ssh   # imprime o comando sem aspas; copie e execute
```

Na primeira conexão, o SSH pergunta se você confia no servidor (`Are you sure you want to continue connecting?`): digite `yes`.

> Se der `Connection timed out` logo após o `apply`, a instância ainda pode estar ligando. Espere um minuto e tente de novo.

### 8. Conferir se o `user_data.sh` terminou

O `apply` termina quando a AWS confirma que a instância existe, mas o `user_data.sh` continua rodando lá dentro em segundo plano. Já dentro da instância:

```bash
cloud-init status --wait   # espera o script acabar; o esperado é "status: done"
docker --version
git --version
docker run hello-world     # testa o Docker sem sudo
```

> Se o `docker run` der `permission denied` no `docker.sock`, você entrou antes de o script adicionar o usuário ao grupo `docker`. Saia (`exit`) e entre de novo.

### 9. `terraform destroy`

```bash
terraform destroy
```

Remove tudo o que o Terraform criou (instância, security group e key pair na AWS; sua chave local continua no computador) e também pede `yes`. **Rode sempre ao terminar de usar**: a instância e o IP público podem gerar cobrança enquanto existirem. O próximo `apply` cria uma instância nova, com outro IP.

---

## O que o `user_data.sh` faz

É executado pelo **cloud-init**, como `root`, **uma única vez**, no primeiro boot da instância:

| Linha | Função |
|---|---|
| `set -e` | Interrompe o script no primeiro comando que falhar |
| `export DEBIAN_FRONTEND=noninteractive` | Impede que o `apt` pare esperando respostas no terminal |
| `apt-get update` | Atualiza a lista de pacotes disponíveis |
| `apt-get install -y docker.io git` | Instala o Docker (pacote do Ubuntu) e o Git |
| `systemctl enable --now docker` | Inicia o Docker agora e configura para iniciar em todo boot |
| `usermod -aG docker ubuntu` | Adiciona o usuário `ubuntu` ao grupo `docker`, permitindo usar o Docker sem `sudo` |

O log completo fica em `/var/log/cloud-init-output.log`, dentro da instância.


---

## Decisões de projeto

- **SSH e API liberados só para o meu IP (`/32`)**: as portas 22 e 3000 só aceitam conexões vindas do IP público.
- **`ignore_changes = [ami]`**: o `data.aws_ami` sempre busca a imagem mais recente. Sem essa regra, toda vez que a Canonical publicasse uma imagem nova, o Terraform tentaria destruir e recriar a instância.
- **Arquivos sensíveis fora do Git**: o `.gitignore` bloqueia chaves (`*.pem`), state (`*.tfstate`, que guarda IDs, IPs e às vezes segredos) e `*.tfvars`.
- **Versão do provider fixada** em `terraform.tf` e travada no `.terraform.lock.hcl`: quem clonar usa exatamente a mesma versão.

---
