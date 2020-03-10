variable "location" {
  type = "string"
  description = "The Location for Infra centre"
  default     = "West Europe"
}

variable "environment" {
  type        = "string"
  description = "The environment name"
}

/*
variable "rg_name" {
  type = "string"
  description = "The resource group name for the resources"
} */


variable "app_name" {
  type = "string"
  description = "Application name of IFRS project"
  default = "sas"
}

/*
variable "storage_type" {
  type = "string"
  description = "Storage type for the compute resource"
} */

variable "cost_center" {
  type = "string"
  description = "The cost_center name for this porject"
  default = "ifrs"
}

variable "company" {
  type = "string"
  description = "The cost_center name for this porject"
  default = "Atradius"
}

variable "dept" {
  type = "string"
  description = "The cost_center name for this porject"
  default = "ITS"
}
variable "owner" {
  type = "string"
  description = "The name of the infra provisioner or owner"
  default = "Prem"
}

variable "vm_name" {
  type = "string"
  description = "The Compute resource name"
}

variable "username" {
  type = "string"
  description = "The root user name for the compute resource"
}

variable "password" {
  type = "string"
  description = "The root password for the compute resource"
}

variable "vm_size" {
  type = "string"
  description = "The Size for all the compute resource"
}

/*
variable "tags" {
  type = "string"
  description = "Tags for the resources"
}
*/
        #nic#
variable "ipconf_name" {
  type = "string"
  description = "The nic name for the compute resource"
}
/*
variable "enable_ip_forwarding" {
  type = "string"
  description = "The nic name for the compute resource"
  #value = false
} */

/*
variable "dns_servers" {
  type = "string"
  description = "The nic name for the compute resource"
  value = ""
}
*/

/*
variable "network_security_group_id" {
  type = "string"
  description = "The nic name for the compute resource"
} */

variable "nic_name" {
  type = "string"
  description = "The nic name for the compute resource"
}

variable "vnet_name" {
  type = "string"
  description = "The core network environment vnet name"
}

variable "vnet_rg_name" {
  type = "string"
  description = "The core network vnet resource group name"
}

variable "subnet_name" {
  type = "string"
  description = "The core network subnet resource name"
}

variable "pdns_api_key" {
  description = "API key to connect to powerdns"
  default = "TMSpub1lt3UfqbDGQxEXY1p+W3IIo+ktwtJMUPtEFQ0="
}

variable "pdns_server_url" {
  description = "The powerdns server ip"
  default = "10.224.36.68"
}

variable "zone_name" {
  type = "string"
  description = "Zone name of the powerdns"
  default = "analytics.atradiusnet.com"
}

#### Network rule

variable "rule_name" {
  type = list(string)
  description = "Names of the rules"
}

variable "rule_description" {
  type = list(string)
  description = "Short description for the rule"
}

variable "rule_portrange" {
  type = list(number)
  description = "Define the port need to be opened"
}