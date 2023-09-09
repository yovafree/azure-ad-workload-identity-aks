# Variables
variable "resource_group_name" {
  description = "Nombre del grupo de recursos"
  type        = string
  default     = "myResourceGroup"
}

variable "location" {
  description = "Ubicación de recursos"
  type        = string
  default     = "centralus"
}

variable "cluster_name" {
  description = "Nombre del clúster AKS"
  type        = string
  default     = "myAKSCluster"
}

variable "user_assigned_identity_name" {
  description = "Nombre de la Identidad asignada por el usuario"
  type        = string
  default     = "myIdentity"
}

variable "keyvault_name" {
  description = "Nombre del Azure Key Vault"
  type        = string
  default     = "akvlatino-net-online"
}
