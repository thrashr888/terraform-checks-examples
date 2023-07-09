
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
  address_prefixes     = ["10.0.2.0/24"]
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

check "check_vm_state" {
  assert {
    condition = azurerm_virtual_machine.main.power_state == "running"
    error_message = format("Virtual Machine (%s) should be in a 'running' status, instead state is '%s'",
      azurerm_virtual_machine.main.id,
      azurerm_virtual_machine.main.power_state
    )
  }
}

# ----------------------------

locals {
  month_in_hour_duration = "${24 * 30}h"
}

resource "azurerm_app_service_certificate" "example" {
  name                = "example-cert"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  pfx_blob            = filebase64("certificate.pfx")
  password            = "terraform"
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

resource "azurerm_storage_account" "example" {
  name                     = "linuxfunctionappsa"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "example" {
  name                = "example-app-service-plan"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_function_app" "example" {
  name                = "example-linux-function-app"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  storage_account_name       = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key
  service_plan_id            = azurerm_service_plan.example.id

  site_config {}
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
