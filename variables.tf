variable "admin_user" {
  type        = string
  description = "Username of VM admin"
}

variable "allowed_cidr" {
  type        = string
  description = "CIDR range to allow SSH from"
}

variable "location" {
  type        = string
  description = "Location to create resources in"
}

variable "plan" {
  type        = map(string)
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
