resource "azurerm_public_ip" "pip" {
  count               = var.vm_count
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
    name                          = "primary"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip[count.index].id
  }
}

resource "azurerm_network_interface_security_group_association" "assoc" {
  count                     = var.vm_count
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = var.network_security_group_id
}

resource "azurerm_linux_virtual_machine" "vm" {
  count                 = var.vm_count
  name                  = format("${var.prefix}-vm%02d", count.index)
  location              = var.location
  resource_group_name   = var.resource_group_name
  size                  = var.vm_size
  admin_username        = var.admin_user
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  custom_data           = var.custom_data

  admin_ssh_key {
    username   = var.admin_user
    public_key = var.public_key
  }

  os_disk {
    name                 = format("${var.prefix}-vm%02d-osdisk", count.index)
    caching              = "ReadWrite"
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
    for_each = [var.plan]
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
