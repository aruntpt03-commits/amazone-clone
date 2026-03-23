
variable "admin_username" {
  description = "The admin username for the EC2 instance."
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "The admin password for the EC2 instance."
  type        = string
  default     = "Password123!"
}
variable "rg_name" {
  description = "The name of the resource group."
  type        = string
  default     = "example-rg"
}

variable "location" {
  description = "The Azure region where the resources will be created."
  type        = string
  default     = "centralus"
}