variable "resource_group_name" {
  description = "Resource Group Name"
  default     = "dns-conditional-service"
}

variable "location" {
  description = "Location"
  default     = "westeurope"
}

variable "admin_username" {
  description = "Login User"
  default     = "myadmin"
}

variable "admin_password" {
  description = "Login Password"
  default     = "test123!"
}

variable "cloudconfig_file" {
  description = "The location of the cloud init configuration file."
  default     = "../cloud-init.txt"
}