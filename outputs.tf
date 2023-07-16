output "lb_backend_pool_id" {
  value = var.create_load_balancer ? azurerm_lb_backend_address_pool.backend[0].id : null
}

output "lb_frontend_config" {
  value = var.create_load_balancer ? local.lb_fe_ip_config : null
}

output "lb_id" {
  value = var.create_load_balancer ? azurerm_lb.lb[0].id : null
}

output "lb_public_ip" {
  value = var.create_load_balancer ? azurerm_public_ip.lb[0].ip_address : null
}

output "vm_public_ips" {
  value = zipmap(azurerm_linux_virtual_machine.vm[*].name, azurerm_public_ip.vm[*].ip_address)
}
