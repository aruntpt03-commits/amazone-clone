#!/bin/bash

# ─── SYSTEM UPDATE ───
sudo apt-get update -y
sudo apt-get upgrade -y

# ─── INSTALL AWS CLI ───
sudo apt install unzip -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# ─── INSTALL DOCKER ───
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker ubuntu
sudo chmod 777 /var/run/docker.sock
docker --version

# ─── INSTALL SONARQUBE ───
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community

# ─── INSTALL TRIVY ───
sudo apt-get install -y wget apt-transport-https gnupg
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update -y
sudo apt-get install -y trivy

# ─── INSTALL JAVA 17 ───
sudo apt-get install -y fontconfig openjdk-17-jdk openjdk-17-jre
java -version

# ─── INSTALL JENKINS ───
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# ─── WAIT FOR JENKINS TO INITIALIZE ───
sleep 30

# ─── OUTPUT ACCESS INFO ───
ip=$(curl -s ifconfig.me)
pass=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
echo "========================================="
echo "Jenkins  --> http://$ip:8080"
echo "Password --> $pass"
echo "SonarQube --> http://$ip:9000"
echo "SonarQube Login --> admin / admin"
echo "========================================="