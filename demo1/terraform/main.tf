# Recurso: Grupo de recursos
resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

# Recurso: Clúster de AKS
resource "azurerm_kubernetes_cluster" "example" {
  name                = var.cluster_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = var.cluster_name
  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }
  identity {
    type = "SystemAssigned"
  }
  addon_profile {
    oms_agent {
      enabled                    = false
    }
    kube_dashboard {
      enabled = true
    }
  }
}

# Recurso: Identidad asignada por el usuario
resource "azurerm_user_assigned_identity" "example" {
  name                = var.user_assigned_identity_name
  resource_group_name = azurerm_resource_group.example.name
}

# Recurso: Key Vault
resource "azurerm_key_vault" "example" {
  name                = var.keyvault_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  enabled_for_disk_encryption = true
  tenant_id           = data.azurerm_client_config.current.tenant_id
}

# Configuración de permisos para Key Vault
resource "azurerm_key_vault_access_policy" "example" {
  key_vault_id = azurerm_key_vault.example.id

  tenant_id = data.azurerm_client_config.current.tenant_id

  # Permiso para la entidad administrada del clúster AKS
  identity {
    type                  = "UserAssigned"
    identity_ids          = [azurerm_user_assigned_identity.example.id]
    identity_ids_list_ids = []
  }

  secret_permissions = [
    "get",
    "list",
    "set",
  ]
}

# Asignación de permisos basados en roles
resource "azurerm_role_assignment" "example" {
  principal_id = azurerm_user_assigned_identity.example.principal_id
  role_definition_name = "Reader"
  scope = azurerm_resource_group.example.id
}