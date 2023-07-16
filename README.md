#  Azure VM Terraform Module

Simple [Terraform module](https://developer.hashicorp.com/terraform/language/modules)
to create one or more Azure VMs.

See [variables.tf](variables.tf) for required inputs, and my
[azure-rocky9-vm](https://github.com/simonbrady/azure-rocky9) repo for
an example of calling the module.

## Change Log

* 1.0.0 - Initial version
* 1.1.0 - Support data disks
* 2.0.0 - Require caller to provide NSG; support VM custom data
* 2.0.1 - Create VMs in availability set
* 2.1.0 - Support optional load balancer
