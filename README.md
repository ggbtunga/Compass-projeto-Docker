# Atividade Docker #PB - NOV 2024 | DevSecOps

Este projeto apresenta uma implementação prática de alta disponibilidade e escalabilidade utilizando AWS. Nele, configuramos um ambiente WordPress com balanceamento de carga, escalabilidade automática e armazenamento persistente. A infraestrutura inclui instâncias EC2 em múltiplas zonas de disponibilidade (AZs), um Application Load Balancer (ALB), um Auto Scaling Group (ASG), um banco de dados gerenciado no Amazon RDS e armazenamento compartilhado via Amazon EFS. O objetivo é garantir uma aplicação resiliente e eficiente, explorando boas práticas de arquitetura na nuvem.

## Arquitetura 

![Image](https://github.com/user-attachments/assets/3d1297fa-de16-4ccd-bfb8-508cb23fb101)

### Pré-requisitos
- **Conhecimentos em Docker**
- **Noções básicas em Linux**
- **Conta na AWS com permissões:**  
  - VPC 
  - NAT Gateway
  - EFS
  - RDS
  - EC2
  - Load Balancer
  - Auto Scaling Group


## Índice

 1. [Configuração da VPC](#1-configuração-da-vpc)
 2. [Configuração dos Security Groups](#2-configuração-dos-security-groups)
 3. [Configuração do File System](#3-configuração-do-file-system)
 4. [Configuração do RDS](#4-configuração-do-rds)
 5. [Configuração do template EC2](#5-configuração-do-template-ec2)
 6. [Configuração do Load Balancer](#6-configuração-do-load-balancer)
 7. [Configuração do Auto Scaling Group](#7-configuração-do-auto-scaling-group)
 8. [Teste e Validação](#8-teste-e-validação)

## 1. Configuração da VPC
#### 1.1 Pesquise por VPC, nas opções à esquerda clique em **Your VPCs**.

1. Create VPC.
2. Selecione : `VPC and more`.
3. Escolha uma name tag para sua vpc: `wp-docker`.
4. IPV4 CIDR block: `10.0.0.0/16`.
5. Número de zonas disponíveis: `2`.
6. Número de subredes públicas: `2`.
7. Número de subredes privadas: `2`.
8. Customize os CIDR Blocks das subredes: `x.x.x.x/24`.
9. NAT gateways: `None`.
10. Create VPC.

#### 1.2 Nas opções à esquerda, clique em **NAT gateways**.
1. Create NAT gateway.
2. Escolha um nome para sua NAT gateway: `wp-natgateway`.
3. Selecione uma subrede pública que pertence a sua VPC.
4. Clique em `Allocate Elastic IP` para associar à um IP elástico.
5. Create NAT gateway.

Aguarde o estado do seu NAT gateway ficar como **Available** para prosseguir. 

#### 1.3 Associe seu NAT gateway nas tabelas de rotas. 

Nas opções à esquerda, clique em **Route Tables**. Identifique as duas subredes privadas criadas pela sua VPC. Clique no ID de cada um vá em Edit routes.

1. Add route
2. Destination: `0.0.0.0/0`
3. Target: `NAT Gateway` e o id da sua nat gateway

![Image](https://github.com/user-attachments/assets/0f2b5c7e-429a-42d9-bcdc-5b4170f59dc2)

## 2. Configuração dos Security Groups

Navegue até EC2 e procure por **Security Groups**. Serão criados 4 security groups no total, para o **EC2**, **Load Balancer**, **EFS** e **RDS**.

#### 2.1 Security Group EC2: SG-EC2

* Inbound rules

| Type          | Port Range    | Source        |
| ------------- |:-------------:|:-------------:|
| MySQL/Aurora  | 3306          | SG-RDS        |
| NFS           | 2049          | SG-EFS        |
| HTTP          | 80            | SG-LB         |
    
* Outbound rules

| Type          | Port Range    | Source        |
| ------------- |:-------------:|:-------------:|
| All traffic   | All           | 0.0.0.0/0     |

#### 2.2 Security Group Load Balancer: SG-LB

* Inbound rules

| Type          | Port Range    | Source        |
| ------------- |:-------------:|:-------------:|
| HTTP          | 80            | 0.0.0.0/0     |

* Outbound rules

| Type          | Port Range    | Source        |
| ------------- |:-------------:|:-------------:|
| HTTP          | 80            | SG-EC2        |
    
#### 2.3 Security Group EFS: SG-EFS

* Inbound rules

| Type          | Port Range    | Source        |
| ------------- |:-------------:|:-------------:|
| NFS           | 2049          | SG-EC2        |

* Outbound rules

| Type          | Port Range    | Source        |
| ------------- |:-------------:|:-------------:|
| All traffic   | All           | 0.0.0.0/0     |

#### 2.4 Security Group RDS: SG-RDS

* Inbound rules

| Type          | Port Range    | Source        |
| ------------- |:-------------:|:-------------:|
| MySQL/Aurora  | 3306          | SG-EC2        |

* Outbound rules

| Type          | Port Range    | Source        |
| ------------- |:-------------:|:-------------:|
| MySQL/Aurora  | 3306          | 0.0.0.0/0     |


## 3. Configuração do File System 
#### 3.1 Navegue até EFS e clique em **Create file system**.

1. Customize
2. Escolha um nome para seu EFS: `wp-efs`.
3. Deixe como `Regional`.
4. Em **Network**, selecione sua VPC.
5. Em **Mount targets**, em cada zona de disponibilidade, selecione o `SG-EFS` no **Security groups**.
6. Create.

![Image](https://github.com/user-attachments/assets/94675508-abe5-4d98-bb40-2d20099c7dc5)

## 4. Configuração do RDS
#### 4.1 Navegue até RDS, nas opções à esquerda clique em Databases e Create database.

1. `Standart create`.
2. Selecione o `MySQL`.
3. Escolha uma versão compatível com WordPress: `MySQL 8.0.39`.
4.  **Templates**: `Free tier`.
5.  Escolha um identificador para o banco de dados.
6.  Escolha uma senha para o banco de dados.
7.  **Instance configuration**: `db.t3.micro`
8.  **Public Access**: `No`
9.  Selecione sua **VPC**.
10.  Selecione o grupo de segurança: `SG-RDS`
11.  **Availability Zone**: `No preference`
12.  **Additional configuratioal**, escolha um nome para seu banco de dados.
13.  Create database.

![Image](https://github.com/user-attachments/assets/98cce3f3-28b8-4fb3-8f04-588b11f36b2b)

## 5. Configuração do template EC2
#### 5.1Navegue até EC2, nas opções à esquerda, vá em Launch Templates e clique em Create launch template.

1. Escolha um nome para o template: `wp-dockerAMI`.
2. Escolha uma AMI: `Amazon Linux 2 Kernel`.
3. Tipo de instância: `t2.micro`.
4. Selecione/crie um par de chaves.
5. Não inclua uma subrede.
6. Selecione o grupo de segurança: `SG-EC2`
7. Adicione as tags de instância e volume.
8. Em **Advanced details**, vá até o **User data** e insira o arquivo user_data.sh .
9. Create launch template.

```bash
#!/bin/bash

# Variáveis
EFS_VOLUME="/mnt/efs"
WORDPRESS_VOLUME="/var/www/html"
DATABASE_HOST="wp-database.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com"
DATABASE_USER="admin"
DATABASE_PASSWORD="12345678"
DATABASE_NAME="wpdatabase"

# Atualização do sistema
sudo yum update -y

# Instalação do Docker e do utilitário EFS
sudo yum install docker -y
sudo yum install amazon-efs-utils -y

# Adição do usuário ao grupo Docker
sudo usermod -aG docker $(whoami)

# Inicialização e ativação do serviço Docker
sudo systemctl start docker
sudo systemctl enable docker

# Criação do ponto de montagem EFS
sudo mkdir -p $EFS_VOLUME

# Montagem do volume EFS
if ! mountpoint -q $EFS_VOLUME; then
  echo "Montando volume EFS..."
  sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-xxxxxxxxxxxxxxxxx.efs.us-east-1.amazonaws.com:/ $EFS_VOLUME
else
  echo "Volume EFS já montado."
fi

# Ajuste de permissões do EFS
sudo chown -R 33:33 $EFS_VOLUME   # Usuário do Apache/Nginx no container
sudo chmod -R 775 $EFS_VOLUME

# Download do Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /bin/docker-compose
chmod +x /bin/docker-compose

# Criação do arquivo docker-compose.yaml
cat <<EOL > /home/ec2-user/docker-compose.yaml
version: '3.8'
services:
  wordpress:
    image: wordpress:latest
    volumes:
      - $EFS_VOLUME$WORDPRESS_VOLUME:/$WORDPRESS_VOLUME
    ports:
      - 80:80
    environment:
      WORDPRESS_DB_HOST: $DATABASE_HOST
      WORDPRESS_DB_USER: $DATABASE_USER
      WORDPRESS_DB_PASSWORD: $DATABASE_PASSWORD
      WORDPRESS_DB_NAME: $DATABASE_NAME
EOL

# Inicialização do serviço WordPress
docker-compose -f /home/ec2-user/docker-compose.yaml up -d
```
#### Nota
Substitua o `fs-xxxxxxxxxxxxxxxxx.efs.us-east-1.amazonaws.com` pelo DNS do seu **EFS** e o `wp-database.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com` pelo endpoint de seu **RDS**.

## 6. Configuração do Load Balancer
#### 6.1 Vá em EC2, nas opções à esquerda, em **Target Groups** clique em **Create target group**.

1. Tipo: `Instances`
2. **Protocol:Port** como `HTTP:80`
3. Selecione sua **VPC**.
4. Next e **Create target group**

![Image](https://github.com/user-attachments/assets/04572665-388f-4e12-b874-adb30fe38af9)

#### 6.2 Agora vá em **Load Balancers** e **Create load balancer**.

1. **Application Load Balancer** clique em **Create**.
2. Escolha um nome do load balancer: `wp-alb`.
3. `Internet-facing` e IPV4.
4. Escolha sua **VPC**.
5. Selecione as **2** zonas de disponibilidade e suas subredes públicas.
6. Selecione o grupo de segurança: SG-LB
7. Em **Listeners and routing** selecione o grupo de destino que foi criado.
8. Create load balancer.

![Image](https://github.com/user-attachments/assets/1cbd2701-1a79-4751-b9a2-cd635d0ff09f)

## 7. Configuração do Auto Scaling Group
#### 7.1 Nas opções à esquerda, vá em **Auto Scaling Groups** e clique em **Create Auto Scaling group**.

1. Escolha um nome para seu **ASG**: `wp-asg`.
2. Selecione sua **VPC**.
3. Escolha as **2** subredes privadas da sua **VPC**.
4. **Attach to an existing load balancer**.
5. Vincule o grupo de destino criado.
6. Habilite o health cheks ELB.
7. Capacidade desejada: `2`
8. Capacidade mínima: `2`
9. Capacidade máxima: `4`
10. **Target tracking scaling policy**
11. **Target tracking scaling policy** insira um valor desejado: `2`
12. **Create Auto Scaling group**.

## 8. Testes e Validação
#### 8.1 Aguarde as instâncias serem inicializadas e em seguida vá para o Load Balancer. Verifique se o estado do Load Balancer está como Active.

![Image](https://github.com/user-attachments/assets/5646f443-4e94-4c29-9263-916558c9e41c)

![Image](https://github.com/user-attachments/assets/c5067bb3-5c62-4f2f-8b47-37b7f08bf751)
#### 8.2 Copie o DNS name do Load Balancer gerado e cole no navegador.
#### 8.3 Configure uma conta de login e instale o wordpress.
![Image](https://github.com/user-attachments/assets/8e86a95c-bf9d-46d2-a14f-045e52163638)

![Image](https://github.com/user-attachments/assets/37f6c68f-d4a7-4867-b084-fa1606830d37)

![Image](https://github.com/user-attachments/assets/778b0805-666a-4ae0-9252-5d738765b163)
## Conclusão
Com a conclusão deste projeto, foi possível configurar um ambiente WordPress altamente disponível na AWS, utilizando Load Balancer, Auto Scaling, RDS e EFS para garantir persistência de dados e escalabilidade. A implementação permite que novas instâncias EC2 sejam criadas automaticamente conforme a demanda, garantindo um ambiente robusto e sem pontos únicos de falha. Seguindo essa documentação, você será capaz de replicar essa infraestrutura para hospedar aplicações web escaláveis e resilientes na nuvem.

## Licença
Este projeto está licenciado sob a [MIT License](LICENSE).

## Créditos
Projeto desenvolvido como parte da Atividade Docker para #PB - NOV 2024 | DevSecOps.

