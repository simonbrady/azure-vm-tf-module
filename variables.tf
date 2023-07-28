variable "admin_user" {
  type        = string
  description = "Username of VM admin"
}

variable "assign_public_ip" {
  type        = bool
  default     = true
  description = "Whether to assign public IPs to the VMs"
}

variable "create_load_balancer" {
  type        = bool
  default     = false
  description = "Whether to create a load balancer in front of the VMs"
}

variable "custom_data" {
  type        = string
  default     = null
  description = "Base64-encoded data to process with cloud-init"
}

variable "data_disk_sizes" {
  type        = list(number)
  default     = []
  description = "Sizes of data disks to attach, in GB"
}

variable "dns_private_zone_name" {
  type        = string
  default     = null
  description = "Name of DNS zone to create private IP A records in"
}

variable "dns_public_zone_name" {
  type        = string
  default     = null
  description = "Name of DNS zone to create public IP A records in"
}

variable "dns_resource_group_name" {
  type        = string
  default     = null
  description = "Resource group containing public and private DNS zones"
}

variable "dns_ttl" {
  type        = number
  default     = 300
  description = "Time-to-live in seconds for DNS records"
}

variable "fault_domain_count" {
  type        = number
  default     = 3
  description = "Number of fault domains in selected location"
}

variable "load_balancer_dns_name" {
  type        = string
  default     = null
  description = "Custom public DNS name for load balancer, overrides default if set"
}

variable "location" {
  type        = string
  description = "Location to create resources in"
}

variable "network_security_group_id" {
  type        = string
  description = "ID of network security group to associate with each NIC"
}

variable "os_disk_size" {
  type        = number
  default     = null
  description = "Size of persistent OS disk in GB, overrides image default if set"
}

variable "plan" {
  type        = map(string)
  default     = {}
  description = "Values for VM plan block"
}

variable "prefix" {
  type        = string
  description = "Common prefix for resource names"
}

variable "public_key" {
  type        = string
  description = "SSH RSA public key for admin user"
}

variable "resource_group_name" {
  type        = string
  description = "Name of resource group to create resources in"
}

variable "source_image_reference" {
  type        = map(string)
  description = "Values for VM source_image_reference block"
}

variable "subnet_id" {
  type        = string
  description = "ID of subnet to attach NIC to"
}

variable "vm_count" {
  type        = number
  default     = 1
  description = "Number of VMs to create"
}

variable "vm_size" {
  type        = string
  description = "Size of VMs to create, e.g. Standard_B2s"
}
