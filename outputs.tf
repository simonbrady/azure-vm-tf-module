output "lb_backend_pool_id" {
  value = var.create_load_balancer ? azurerm_lb_backend_address_pool.backend[0].id : null
}

output "lb_frontend_config" {
  value = var.create_load_balancer ? local.lb_fe_ip_config : null
}

output "lb_id" {
  value = var.create_load_balancer ? azurerm_lb.lb[0].id : null
}

output "lb_dns_name" {
  value = (var.create_load_balancer && var.dns_public_zone_name != null) ? azurerm_dns_a_record.lb[*].fqdn : null
}

output "lb_public_ip" {
  value = var.create_load_balancer ? azurerm_public_ip.lb[0].ip_address : null
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
