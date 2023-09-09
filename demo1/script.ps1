# Variables iniciales
$RESOURCE_GROUP="myResourceGroup"
$LOCATION="centralus"
$SERVICE_ACCOUNT_NAMESPACE="default"
$SERVICE_ACCOUNT_NAME="workload-identity-sa"
$SUBSCRIPTION="$(az account show --query id --output tsv)"
$USER_ASSIGNED_IDENTITY_NAME="myIdentity"
$FEDERATED_IDENTITY_CREDENTIAL_NAME="myFedIdentity"
$CLUSTER_NAME="myAKSCluster"
$KEYVAULT_NAME="akvlatino-net-online1"

# Creacion de grupo de recursos en Azure
az group create --name "${RESOURCE_GROUP}" --location "${LOCATION}"

# Creación de clúster de AKS, se habilita workload identity y OIDC
az aks create -g "${RESOURCE_GROUP}" -n $CLUSTER_NAME --enable-oidc-issuer --enable-workload-identity --generate-ssh-keys

# Obtener la dirección URL del emisor de OIDC
$AKS_OIDC_ISSUER="$(az aks show -n $CLUSTER_NAME -g "${RESOURCE_GROUP}" --query "oidcIssuerProfile.issuerUrl" -otsv)"

# Creación de una entidad administrada
az identity create --name "${USER_ASSIGNED_IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP}" --location "${LOCATION}" --subscription "${SUBSCRIPTION}"

# Obtener el ID de la Entidad Administrada (Se utilizará la opción User Assigned de una Entidad Administrada)
$USER_ASSIGNED_CLIENT_ID="$(az identity show --resource-group "${RESOURCE_GROUP}" --name "${USER_ASSIGNED_IDENTITY_NAME}" --query 'clientId' -otsv)"

# Obtener credenciales de AKS para Kubectl
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing

# Creación de cuenta de servicios de Kubernetes
$k8sServiceAccountWI = @"
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: "$($USER_ASSIGNED_CLIENT_ID)"
  name: "$($SERVICE_ACCOUNT_NAME)"
  namespace: "$($SERVICE_ACCOUNT_NAMESPACE)"
"@

# Despliegue de la cuenta de servicios para kubernetes
$k8sServiceAccountWI | kubectl apply -f -

# Creación de la Identidad Federada
az identity federated-credential create --name ${FEDERATED_IDENTITY_CREDENTIAL_NAME} --identity-name "${USER_ASSIGNED_IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP}" --issuer "${AKS_OIDC_ISSUER}" --subject system:serviceaccount:"${SERVICE_ACCOUNT_NAMESPACE}":"${SERVICE_ACCOUNT_NAME}" --audience api://AzureADTokenExchange

# Habilitar un permiso basado en rol de lectura a los recursos del grupo de recursos para la entidad administrada.
az role assignment create --role "Reader" --assignee ${USER_ASSIGNED_CLIENT_ID} --scope /subscriptions/$SUBSCRIPTION/resourcegroups/$RESOURCE_GROUP

# Creación de un recurso Azure Key Vault
az keyvault create --name $KEYVAULT_NAME --resource-group $RESOURCE_GROUP --location $LOCATION

# Se habilitan los permisos para Azure Key Vault
az keyvault set-policy --name "${KEYVAULT_NAME}" --secret-permissions get list set --spn "${USER_ASSIGNED_CLIENT_ID}"

