output "vm_public_ips" {
  value = zipmap(azurerm_linux_virtual_machine.vm[*].name, azurerm_public_ip.pip[*].ip_address)
}
