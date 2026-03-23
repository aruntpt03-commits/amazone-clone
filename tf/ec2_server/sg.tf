resource "azurerm_network_security_group" "nsg" {
  name                = "nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  #Allow SSH
  security_rule {
    name                       = "AllowSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  #allow HTTP
    security_rule {
        name                       = "AllowHTTP"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
  #allow HTTPS
    security_rule {
        name                       = "AllowHTTPS"
        priority                   = 1003
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

   #port 2379-2380 for etcd
    security_rule {
        name                       = "AllowETCD"
        priority                   = 1004
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["2379-2380"]
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    #port 3000 for grafana
    security_rule {
        name                       = "AllowGrafana"
        priority                   = 1005
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3000"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    # port 6443 for kubernetes API server
    security_rule {
        name                       = "AllowK8sAPI"
        priority                   = 1006
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "6443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    # port 8080 for jenkins
    security_rule {
        name                       = "AllowJenkins"
        priority                   = 1007
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8080"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    #port 9000 for sonarqube
    security_rule {
        name                       = "AllowSonarQube"
        priority                   = 1008
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "9000"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    #port 9090 for prometheus
    security_rule {
        name                       = "AllowPrometheus"
        priority                   = 1009
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "9090"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    #port 9100 for prometheus metric server
    security_rule {
        name                       = "AllowPrometheusNodeExporter"  
        priority                   = 1010   
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "9100"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    #port 10250-10260 for kubernetes kubelet API
    security_rule {
        name                       = "AllowKubeletAPI"
        priority                   = 1011
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["10250-10260"]
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    #port 30000-32767 for kubernetes nodeport services
    security_rule {
        name                       = "AllowK8sNodePort"
        priority                   = 1012
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["30000-32767"]
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    #port 8080 for jenkins agent
    security_rule {
        name                       = "AllowJenkinsAgent"
        priority                   = 1013
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8080"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
  # outbound rule to allow all traffic
    security_rule {
        name                       = "AllowAllOutbound"
        priority                   = 1000
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

}