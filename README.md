# Bind9 Conditional Forwarder

## Prerequisite 
```
git clone https://github.com/derdanu/bind9-conditional-forwarder.git
cd bind9-conditional-forwarder
```
## Create a single Azure VM using CLI and the cloudinit file 
```
export GROUP=dns
az group create --name $GROUP --location westeurope
az vm create \
    --resource-group $GROUP \
    --name dns --image UbuntuLTS \
    --admin-username azureuser \
    --admin-password Test123#123# \
    --nsg ""  \
    --custom-data cloud-init.txt
```

## Create a Azure VMSS using Terraform and the cloudinit file
```
cd tf 
vi variables.tf
terraform init
terraform plan
terraform apply 
```

