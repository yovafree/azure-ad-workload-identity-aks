## Crear un Pod de Verificación (Powershell)
```
$k8sPod = @"
apiVersion: v1
kind: Pod
metadata:
  name: quick-start
  namespace: default
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: workload-identity-sa
  containers:
  - name: azcli
    image: mcr.microsoft.com/azure-cli
    command:
    - "/bin/bash"
    - "-c"
    - "sleep infinity"
  nodeSelector:
    kubernetes.io/os: linux
"@

$k8sPod | kubectl apply -f -
```
## Dentro del POD ejecutar lo siguiente
```
az login --federated-token "$(cat $AZURE_FEDERATED_TOKEN_FILE)" --service-principal -u $AZURE_CLIENT_ID -t $AZURE_TENANT_ID

az keyvault secret show --name "secreto1" --vault-name "akvlatino-net-online1" --query "value"
```