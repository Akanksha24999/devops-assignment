#!/bin/bash
set -xe

# 1. System setup
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y ca-certificates curl git gnupg lsb-release

# Add Docker GPG key (correct way)
install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
gpg --dearmor -o /etc/apt/keyrings/docker.gpg

chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repo (correct + clean)
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
> /etc/apt/sources.list.d/docker.list

# 4. Install Docker
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 5. Start Docker
systemctl enable docker
systemctl start docker

# 6. Setup app
APP_DIR="/home/ubuntu/app"
mkdir -p $APP_DIR
cd $APP_DIR

rm -rf .git
git clone https://github.com/Akanksha24999/devops-assignment.git .

# Fix permissions
chown -R ubuntu:ubuntu /home/ubuntu/app
usermod -aG docker ubuntu

# 7. Wait for Docker
sleep 10

# 8. Run app
docker compose up -d --build