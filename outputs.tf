output "lb_backend_pool_id" {
  value = one(azurerm_lb_backend_address_pool.backend[*].id)
}

output "lb_frontend_config" {
  value = var.create_load_balancer ? local.lb_fe_ip_config : null
}

output "lb_id" {
  value = one(azurerm_lb.lb[*].id)
}

output "lb_dns_name" {
  value = one(azurerm_dns_a_record.lb[*].fqdn)
}

output "lb_public_ip" {
  value = one(azurerm_public_ip.lb[*].ip_address)
}

output "vm_private_ips" {
  value = zipmap(
    (var.dns_private_zone_name == null ? azurerm_linux_virtual_machine.vm[*].name : azurerm_dns_a_record.private[*].fqdn),
    azurerm_linux_virtual_machine.vm[*].private_ip_address
  )
}

output "vm_public_ips" {
  value = var.assign_public_ip ? zipmap(
    (var.dns_public_zone_name == null ? azurerm_linux_virtual_machine.vm[*].name : azurerm_dns_a_record.public[*].fqdn),
    azurerm_linux_virtual_machine.vm[*].public_ip_address
  ) : null
}
