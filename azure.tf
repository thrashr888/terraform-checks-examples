
variable "prefix" {
  default = "hashicorp-example"
}

variable "username" {
  default = "pthrasher"
}

variable "password" {
  default = "Password1234!"
}

variable "vm_size" {
  default = "Standard_B1s"
}

# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = "West US"
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = var.vm_size

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix}-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = var.username
    admin_password = var.password

    custom_data = "echo 'init test'"
  }

  os_profile_linux_config {
    disable_password_authentication = true
  }

  tags = {
    environment  = "test"
    owner        = "pthrasher"
    organization = "hashicorp"
    application  = "example"
  }
}


data "azurerm_virtual_machine" "example" {
  name                = azurerm_linux_virtual_machine.example.name
  resource_group_name = azurerm_resource_group.example.name
}
 
check "check_vm_state" {
  assert {
    condition = data.azurerm_virtual_machine.example.power_state == "running"
    error_message = format("Virtual Machine (%s) should be in a 'running' status, instead state is '%s'",
      data.azurerm_virtual_machine.example.id,
      data.azurerm_virtual_machine.example.power_state
    )
  }
}

# ----------------------------

locals {
  month_in_hour_duration = "${24 * 30}h"
}
 
data "azurerm_app_service_certificate" "example" {
  name                = azurerm_app_service_certificate.example.name
  resource_group_name = azurerm_app_service_certificate.example.resource_group_name
}
 
check "check_certificate_state" {
  assert {
    condition = timecmp(plantimestamp(), timeadd(
      data.azurerm_app_service_certificate.example.expiration_date,
      "-${local.month_in_hour_duration}")) < 0
    error_message = format("App Service Certificate (%s) is valid for at least 30 days, but is due to expire on `%s`.",
      data.azurerm_app_service_certificate.example.id,
      data.azurerm_app_service_certificate.example.expiration_date
    )
  }
}

# ---------------------------------
variable "azurerm_linux_function_app_example_name" {

}
variable "azurerm_linux_function_app_example_name" {

}

data "azurerm_linux_function_app" "example" {
  name                = azurerm_linux_function_app.example.name
  resource_group_name = azurerm_linux_function_app.example.resource_group_name
}
 
check "check_usage_limit" {
  assert {
    condition = data.azurerm_linux_function_app.example.usage == "Exceeded"
    error_message = format("Function App (%s) usage has been exceeded!",
      data.azurerm_linux_function_app.example.id,
    )
  }
}
