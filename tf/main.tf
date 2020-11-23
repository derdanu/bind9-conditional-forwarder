provider "azurerm" {
  version = "~>1.44"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "example" {
  name                = "dns-network"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.5.0.0/16"]
}

resource "azurerm_subnet" "example" {
  name                                          = "dns-subnet"
  resource_group_name                           = azurerm_resource_group.example.name
  virtual_network_name                          = azurerm_virtual_network.example.name
  address_prefix                                = "10.5.1.0/24"
}

resource "azurerm_public_ip" "example" {
  name                = "dns-outbound-pip"
  sku                 = "Standard"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "example_ext" {
  name                = "dns-lb-external"
  sku                 = "Standard"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  frontend_ip_configuration {
    name                 = azurerm_public_ip.example.name
    public_ip_address_id = azurerm_public_ip.example.id
  }
}

resource "azurerm_lb_backend_address_pool" "bpepool_ext" {
  resource_group_name = azurerm_resource_group.example.name
  loadbalancer_id     = azurerm_lb.example_ext.id
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_outbound_rule" "example_ext" {
  resource_group_name     = azurerm_resource_group.example.name
  loadbalancer_id         = azurerm_lb.example_ext.id
  name                    = "OutboundRule"
  protocol                = "All"
  backend_address_pool_id = azurerm_lb_backend_address_pool.bpepool_ext.id

  frontend_ip_configuration {
    name = azurerm_public_ip.example.name
  }
}

resource "azurerm_lb" "example" {
  name                = "dns-lb-internal"
  sku                 = "Standard"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  frontend_ip_configuration {
    name      = "internal"
    subnet_id = azurerm_subnet.example.id
  }

}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  resource_group_name = azurerm_resource_group.example.name
  loadbalancer_id     = azurerm_lb.example.id
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_nat_pool" "lbnatpool" {
  resource_group_name            = azurerm_resource_group.example.name
  name                           = "ssh"
  loadbalancer_id                = azurerm_lb.example.id
  protocol                       = "Tcp"
  frontend_port_start            = 50000
  frontend_port_end              = 50119
  backend_port                   = 22
  frontend_ip_configuration_name = "internal"
}

resource "azurerm_lb_rule" "dns_tcp" {
  resource_group_name            = azurerm_resource_group.example.name
  loadbalancer_id                = azurerm_lb.example.id
  name                           = "LBRule_DNS_53_tcp"
  protocol                       = "Tcp"
  frontend_port                  = 53
  backend_port                   = 53
  frontend_ip_configuration_name = "internal"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.bpepool.id
  probe_id                       = azurerm_lb_probe.example.id
}

resource "azurerm_lb_rule" "dns_udp" {
  resource_group_name            = azurerm_resource_group.example.name
  loadbalancer_id                = azurerm_lb.example.id
  name                           = "LBRule_DNS_53_udp"
  protocol                       = "Udp"
  frontend_port                  = 53
  backend_port                   = 53
  frontend_ip_configuration_name = "internal"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.bpepool.id
  probe_id                       = azurerm_lb_probe.example.id
}

resource "azurerm_lb_probe" "example" {
  resource_group_name = azurerm_resource_group.example.name
  loadbalancer_id     = azurerm_lb.example.id
  name                = "dns-running-probe"
  port                = 53
  protocol            = "tcp"
}

resource "azurerm_virtual_machine_scale_set" "example" {
  name                = "proxy-scaleset"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  upgrade_policy_mode = "Manual"

  sku {
    name     = "Standard_F2"
    tier     = "Standard"
    capacity = 2
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name_prefix = "dns"
    admin_username       = var.admin_username
    admin_password       = var.admin_password
    custom_data          = data.template_cloudinit_config.config.rendered
  }

  network_profile {
    name          = "Networkprofile"
    primary       = true
    ip_forwarding = true
    ip_configuration {
      name                                   = "IPConfiguration"
      primary                                = true
      subnet_id                              = azurerm_subnet.example.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id, azurerm_lb_backend_address_pool.bpepool_ext.id]
    }
  }
}

data "template_file" "cloudconfig" {
  template = "${file("${var.cloudconfig_file}")}"
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.cloudconfig.rendered}"
  }
}