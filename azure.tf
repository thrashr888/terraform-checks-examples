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
