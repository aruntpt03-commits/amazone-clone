resource "azurerm_virtual_network" "vn" {   
    name                = "vn"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

#subnet

resource "azurerm_subnet" "sn" {
  name                 = "sn"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefixes     = ["10.0.1.0/24"]
  
}

resource "azurerm_public_ip" "pip" {
  name                = "pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku               = "Standard"
  allocation_method = "Static"
}

resource "azurerm_subnet_network_security_group_association" "assoc" {
  subnet_id                 = azurerm_subnet.sn.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface" "nic" {
  name                = "nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
  name                          = "internal"
  subnet_id                     = azurerm_subnet.sn.id
  private_ip_address_allocation = "Dynamic"
  public_ip_address_id          = azurerm_public_ip.pip.id
}
}

resource "azurerm_linux_virtual_machine" "avm" {
  name                = "avm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_D4s_v3"
  admin_username      = var.admin_username

  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("/home/arun/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  disable_password_authentication = true

  provisioner "remote-exec" {
  inline = [
    "sudo cloud-init status --wait || true",
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo -E apt-get update -y",
      "sudo -E apt-get upgrade -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold'",
      "sudo -E apt-get install -y curl wget gnupg apt-transport-https ca-certificates software-properties-common fontconfig unzip lsb-release",

      # AWS CLI v2
      "echo '>>> Installing AWS CLI v2...'",
      "curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o '/tmp/awscliv2.zip'",
      "unzip -q /tmp/awscliv2.zip -d /tmp/",
      "sudo /tmp/aws/install",
      "rm -rf /tmp/awscliv2.zip /tmp/aws/",
      "aws --version",

      # Docker
      "echo '>>> Installing Docker...'",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "sudo chmod a+r /etc/apt/keyrings/docker.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo -E apt-get update -y",
      "sudo -E apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo usermod -aG docker azureuser",
      "sudo usermod -aG docker jenkins",
      "docker --version",

      # SonarQube
      "echo '>>> Starting SonarQube...'",
      "sudo docker run -d --name sonarqube --restart always -p 9000:9000 -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true sonarqube:lts-community",

      # Trivy
      "echo '>>> Installing Trivy...'",
      "wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /etc/apt/keyrings/trivy.gpg > /dev/null",
      "echo \"deb [signed-by=/etc/apt/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main\" | sudo tee /etc/apt/sources.list.d/trivy.list > /dev/null",
      "sudo -E apt-get update -y",
      "sudo -E apt-get install -y trivy",
      "trivy --version",

      # kubectl
      "echo '>>> Installing kubectl...'",
      "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null",
      "sudo -E apt-get update -y",
      "sudo -E apt-get install -y kubectl",
      "kubectl version --client",

      # Helm
      "echo '>>> Installing Helm...'",
      "curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/helm.gpg > /dev/null",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main\" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list > /dev/null",
      "sudo -E apt-get update -y",
      "sudo -E apt-get install -y helm",
      "helm version",

      # ArgoCD CLI
      "echo '>>> Installing ArgoCD CLI...'",
      "ARGOCD_VERSION=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases/latest | grep '\"tag_name\"' | sed -E 's/.*\"([^\"]+)\".*/\\1/')",
      "curl -sSL -o /tmp/argocd https://github.com/argoproj/argo-cd/releases/download/$${ARGOCD_VERSION}/argocd-linux-amd64",
      "sudo install -m 755 /tmp/argocd /usr/local/bin/argocd",
      "rm /tmp/argocd",
      "argocd version --client",

      # Firewall
      "sudo ufw allow 22/tcp   || true",
      "sudo ufw allow 8080/tcp || true",
      "sudo ufw allow 9000/tcp || true",

      # Summary
      "PUBLIC_IP=$(curl -s ifconfig.me)",
      "echo '=============================================='",
      "echo '   ALL TOOLS INSTALLED SUCCESSFULLY'",
      "echo '=============================================='",
      "echo \"  Jenkins    : http://$PUBLIC_IP:8080\"",
      "echo \"  SonarQube  : http://$PUBLIC_IP:9000  (admin/admin)\"",
      "echo \"  AWS CLI    : $(aws --version)\"",
      "echo \"  Docker     : $(docker --version)\"",
      "echo \"  Trivy      : $(trivy --version | head -1)\"",
      "echo \"  kubectl    : $(kubectl version --client --short 2>/dev/null || kubectl version --client)\"",
      "echo \"  Helm       : $(helm version --short)\"",
      "echo \"  ArgoCD CLI : $(argocd version --client --short 2>/dev/null)\"",
      "echo '=============================================='",
  ]

  connection {
    type        = "ssh"
    user        = var.admin_username
    private_key = file("/home/arun/.ssh/id_rsa")
    host        = azurerm_public_ip.pip.ip_address
  }
}
}