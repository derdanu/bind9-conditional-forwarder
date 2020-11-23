# Bind9 Conditional Forwarder

## Create a Azure  VM using the cloudinit file
```
git clone https://github.com/derdanu/bind9-conditional-forwarder.git
cd bind9-conditional-forwarder
export GROUP=dns
az group create --name $GROUP --location westeurope
az vm create --resource-group $GROUP --name dns --image UbuntuLTS --admin-username azureuser --admin-password Test123#123# --nsg ""  --custom-data cloud-init.txt
```