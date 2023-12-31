# Static values referred to in multiple places
locals {
  nic_ip_config   = "primary"
  lb_fe_ip_config = "frontend_public"
}

# Network config

resource "azurerm_public_ip" "vm" {
  count               = var.assign_public_ip ? var.vm_count : 0
  name                = format("${var.prefix}-pip%02d", count.index)
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = format("${var.prefix}-nic%02d", count.index)
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = local.nic_ip_config
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.assign_public_ip ? azurerm_public_ip.vm[count.index].id : null
  }
}

resource "azurerm_network_interface_security_group_association" "assoc" {
  count                     = var.vm_count
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = var.network_security_group_id
}

# VM config

resource "azurerm_availability_set" "avset" {
  name                        = "${var.prefix}-avset"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  platform_fault_domain_count = var.fault_domain_count
}

resource "azurerm_linux_virtual_machine" "vm" {
  count                 = var.vm_count
  name                  = format("${var.prefix}-vm%02d", count.index)
  location              = var.location
  resource_group_name   = var.resource_group_name
  admin_username        = var.admin_user
  availability_set_id   = azurerm_availability_set.avset.id
  custom_data           = var.custom_data
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  size                  = var.vm_size

  admin_ssh_key {
    username   = var.admin_user
    public_key = var.public_key
  }

  os_disk {
    name                 = format("${var.prefix}-vm%02d-osdisk", count.index)
    caching              = "ReadWrite"
    disk_size_gb         = var.os_disk_size
    storage_account_type = "Standard_LRS"
  }

  dynamic "source_image_reference" {
    for_each = [var.source_image_reference]
    content {
      publisher = source_image_reference.value.publisher
      offer     = source_image_reference.value.offer
      sku       = source_image_reference.value.sku
      version   = source_image_reference.value.version
    }
  }

  dynamic "plan" {
    for_each = (length(var.plan) == 0 ? [] : [var.plan])
    content {
      name      = plan.value.name
      publisher = plan.value.publisher
      product   = plan.value.product
    }
  }
}

# Create map of VM and data disk details: if we have N VMs each with
# M data disks then we have to create N*M disks and attachments.
# vm_disk_combinations is a list of length N*M that iterates over the
# two indices, e.g. if N=2 and M=3 then it will be the list of "coordinates"
# [(0,0), (0,1), (0,2), (1,0), (1,1), (1,2)]. data_disks uses these
# coordinates to construct a map with N*M entries where the key is the
# name of the disk we'll create and the value is an object with details
# we need to create the disk and attach it to the right VM. Using a map
# rather than a list means we can change the values of N or M independently
# without forcing recreation of disks we want to keep.

locals {
  vm_disk_combinations = setproduct(range(var.vm_count), range(length(var.data_disk_sizes)))
  data_disks = { for vm_disk in local.vm_disk_combinations :
    format("${azurerm_linux_virtual_machine.vm[vm_disk[0]].name}-datadisk-%02d", vm_disk[1]) => {
      disk_size_gb = var.data_disk_sizes[vm_disk[1]]
      lun          = vm_disk[1]
      vm_id        = azurerm_linux_virtual_machine.vm[vm_disk[0]].id
    }
  }
}

resource "azurerm_managed_disk" "data" {
  for_each             = local.data_disks
  name                 = each.key
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = each.value.disk_size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "example" {
  for_each           = local.data_disks
  managed_disk_id    = azurerm_managed_disk.data[each.key].id
  virtual_machine_id = each.value.vm_id
  lun                = each.value.lun
  caching            = "ReadWrite"
}

# Load balancer config

resource "azurerm_public_ip" "lb" {
  count               = var.create_load_balancer ? 1 : 0
  name                = "${var.prefix}-lb-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
}

resource "azurerm_lb" "lb" {
  count               = var.create_load_balancer ? 1 : 0
  name                = "${var.prefix}-lb"
  location            = var.location
  resource_group_name = var.resource_group_name

  frontend_ip_configuration {
    name                 = local.lb_fe_ip_config
    public_ip_address_id = azurerm_public_ip.lb[0].id
  }
}

resource "azurerm_lb_backend_address_pool" "backend" {
  count           = var.create_load_balancer ? 1 : 0
  name            = "${var.prefix}-lb-beap"
  loadbalancer_id = azurerm_lb.lb[0].id
}

resource "azurerm_network_interface_backend_address_pool_association" "assoc" {
  count                   = var.create_load_balancer ? var.vm_count : 0
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = local.nic_ip_config
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend[0].id
}

# DNS config

resource "azurerm_dns_a_record" "lb" {
  count               = (var.create_load_balancer && var.dns_public_zone_name != null) ? 1 : 0
  name                = var.load_balancer_dns_name == null ? "${var.prefix}-lb" : var.load_balancer_dns_name
  zone_name           = var.dns_public_zone_name
  resource_group_name = var.dns_resource_group_name
  ttl                 = var.dns_ttl
  records             = [azurerm_public_ip.lb[0].ip_address]
}

resource "azurerm_dns_a_record" "private" {
  count               = var.dns_private_zone_name == null ? 0 : var.vm_count
  name                = format("${var.prefix}-vm%02d", count.index)
  zone_name           = var.dns_private_zone_name
  resource_group_name = var.dns_resource_group_name
  ttl                 = var.dns_ttl
  records             = [azurerm_linux_virtual_machine.vm[count.index].private_ip_address]
}

resource "azurerm_dns_a_record" "public" {
  count               = var.dns_public_zone_name == null ? 0 : var.vm_count
  name                = format("${var.prefix}-vm%02d", count.index)
  zone_name           = var.dns_public_zone_name
  resource_group_name = var.dns_resource_group_name
  ttl                 = var.dns_ttl
  records             = [azurerm_linux_virtual_machine.vm[count.index].public_ip_address]
}
