# resource group 

resource "azurerm_resource_group" "rg" {
  name     = "devops1"
  location = var.location
}