##################################################
# Providers
##################################################
provider "azurerm" {
  version = ">= 1.32.1"
  features {}
}

provider "powerdns" {
  api_key = "${var.pdns_api_key}"
  server_url = "${var.pdns_server_url}"
}

##################################################
# locals for taging
##################################################
locals {
    Owner = "${var.owner}"
    Environment = "${var.environment}"
    Cost_center = "${var.cost_center}"
    Company = "${var.company}"
    Application = "${var.app_name}"
    Dept = "${var.dept}"
  }

locals {
  common_tags = {
    Owner = local.Owner
    Environment = local.Environment
    Cost_center = local.Cost_center
    Company = local.Company
    Application = local.Application
    Dept = local.Dept
  }

}



##################################################
# Azure resource group
##################################################
resource "azurerm_resource_group" "rg" {
  name     = "${var.cost_center}-${var.environment}-${var.app_name}-rg"
  location = "${var.location}"
  tags     = "${local.common_tags}"
}

##################################################
# Azure Vnet
##################################################

data "azurerm_virtual_network" "vnet" {
  name                = "${var.vnet_name}"
  resource_group_name = "${var.vnet_rg_name}"
  #resource_group_name = "${azurerm_resource_group.rg.name}"
}

##################################################
# Azure Subnet
##################################################

data "azurerm_subnet" "subnet" {
  name                 = "${var.subnet_name}"
  virtual_network_name = "${data.azurerm_virtual_network.vnet.name}"
  resource_group_name = "${data.azurerm_virtual_network.vnet.resource_group_name}"
  #resource_group_name = "${var.vnet_rg_name}"
  #virtual_network_name = "${var.vnet_name}"
}

##################################################
# Application security group
##################################################
resource "azurerm_application_security_group" "asg" {
  name                = "sas-${var.environment}-asg"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  tags = "${local.common_tags}"
}



##################################################
# Network security group
##################################################
resource "azurerm_network_security_group" "nsg" {
  name                = "sas-${var.environment}-nsg"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  tags = "${local.common_tags}"
}

##################################################
# Network security rules
##################################################

resource "azurerm_network_security_rule" "rules" {
  #count = "${length(var.rule_portrange)}"
  count = "${length(var.rule_portrange)}"
  #count = 2
  #name = "${index(var.rule_name, count.index)}"
  #name = "${var.rule_name}-${count.index}"
  name = element(["remote_ssh","remote_metadata"], count.index)
  direction = "Inbound"
  #description                                = "${index(var.rule_description, count.index)}"
  #description = [element(var.rule_description, count.index)]
  description = element(["Allow Ssh to sas env","Allow access to metadata server"], count.index)
  source_port_range                          = "*"
  #destination_port_range                     = "${index(var.rule_portrange, count.index)}"
  #destination_port_range = [element(var.rule_portrange, count.index)]
  destination_port_range = element(["22","8561"], count.index)
  source_address_prefix                      = "*"
  #destination_application_security_group_ids = "${azurerm_application_security_group.asg.id}"
  destination_application_security_group_ids = [azurerm_application_security_group.asg.id]
  protocol = "Tcp"
  access = "Allow"
  priority = "${(count.index + 10) * 100}"
  resource_group_name                        = "${azurerm_resource_group.rg.name}"
  network_security_group_name                = "${azurerm_network_security_group.nsg.name}"
}

/*
data "local_file" "rules" {
    filename = "${path.module}/rules/local_file"
}
*/

##################################################
# NSG adding to Subnet
##################################################

resource "azurerm_subnet_network_security_group_association" "nsg_subnet" {
  subnet_id                 = "${data.azurerm_subnet.subnet.id}"
  network_security_group_id = "${azurerm_network_security_group.nsg.id}"
}

##################################################
# Azure NIC
##################################################

resource "azurerm_network_interface" "nic" {
  name                = "${var.nic_name}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  #enable_ip_forwarding      = "${var.enable_ip_forwarding}"
  enable_ip_forwarding = false
  #dns_servers               = "${var.dns_servers}"
  #network_security_group_id = "${azurerm_network_security_group.nsg.id}"

    ip_configuration {
      name = "${var.ipconf_name}"
      private_ip_address_allocation = "Static"
      private_ip_address = "10.0.0.10"
      subnet_id = "${data.azurerm_subnet.subnet.id}"
      #public_ip_address_id           = length(azurerm_public_ip.vm.*.id) > 0 ? element(concat(azurerm_public_ip.vm.*.id, [""]), count.index) : ""
      #application_security_group_ids = "${var.application_security_group_ids}"
    }

  tags = "${local.common_tags}"
}



##################################################
# Azure Compute
##################################################


resource "azurerm_virtual_machine" "compute" {
  name = "${var.vm_name}"
  #vm_hostname      = "${var.vm_name}"
  location = "${var.location}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  #vnet_subnet_id   = "${data.azurerm_subnet.subnet.id}"
  network_interface_ids = ["${azurerm_network_interface.nic.id}"]
  #ssh_key              = "~/.ssh/id_rsa_sas.pub"
  vm_size               = "${var.vm_size}"
  #storage_account_type = "${var.storage_type}"
  delete_os_disk_on_termination       = true
  delete_data_disks_on_termination    = true
  #application_security_group_ids = [
  #  data.terraform_remote_state.sas-base.outputs.application_security_groups["sas"],
  #]

  #boot_diagnostics = "false"
  #data_disk        = "false"
  #provision_vm_agent = "true"

 /* admin_username   = "redhat" */

  storage_image_reference {
    #id        = ""
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "7.5"
    version   = "latest"
  }

  storage_os_disk  {
    name              = "${var.vm_name}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    os_type = "Linux"
    }

  os_profile {
    computer_name  = "${var.vm_name}"
    admin_username = "${var.username}"
    admin_password = "${var.password}"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = "${local.common_tags}"

  #bootstrap        = "true"
  #bootstrap_script = "../scripts/puppet_bootstrap.sh"
  #bootstrap_params = "${join(" ", list("${data.terraform_remote_state.ims.outputs.puppetmaster_ip[0]}", "puppetmaster-0", "production", "node"))}"
  #private_key      = "~/.ssh/id_rsa_sas"
}

resource "azurerm_virtual_machine_extension" "compute_extension" {
  name                 = "${var.vm_name}-extension"
  #location = "${var.location}"
  #location             = "${azurerm_resource_group.rg.location}"
  #resource_group_name = "${azurerm_resource_group.rg.name}"
  #resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_machine_id = "${azurerm_virtual_machine.compute.id}"
  publisher            = "Microsoft.Azure.ActiveDirectory.LinuxSSH"
  type                 = "AADLoginForLinux"
  type_handler_version = "1.0"
  auto_upgrade_minor_version = true
}


##################################################
# disk storage
##################################################
resource "azurerm_managed_disk" "disk_create_ssd" {
  name                 = "${var.vm_name}-dd"
  location             = "${var.location}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = 210
}

resource "azurerm_virtual_machine_data_disk_attachment" "disk_mount_ssd" {
  managed_disk_id    = "${azurerm_managed_disk.disk_create_ssd.id}"
  virtual_machine_id = "${azurerm_virtual_machine.compute.id}"
  lun                = "10"
  caching            = "ReadWrite"
}

resource "azurerm_managed_disk" "disk_create_ultra_ssd" {
  name                 = "${var.vm_name}-ddp"
  location             = "${var.location}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 510
}

resource "azurerm_virtual_machine_data_disk_attachment" "disk_mount_ultra_ssd" {
  managed_disk_id    = "${azurerm_managed_disk.disk_create_ultra_ssd.id}"
  virtual_machine_id = "${azurerm_virtual_machine.compute.id}"
  lun                = "30"
  caching            = "ReadWrite"
}

/*
resource "powerdns_record" "dns" {
  zone    = "${var.zone_name}."
  name    = "${var.app_name}."
  type    = "A"
  ttl     = 300
  records = ["${azurerm_network_interface.nic.id}"]
}
*/






