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