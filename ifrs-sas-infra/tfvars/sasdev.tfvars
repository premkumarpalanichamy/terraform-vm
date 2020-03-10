#rg_name = "ifrs-dev-sas-rg"
environment          = "dev"
vm_name              = "sas-compute-fix"
#vnet_name = "test-sas-vnet"
vnet_name = "MyPackerGroup-vnet"
nic_name = "sas-nic-fix"
#vnet_rg_name = "ifrs-test-sas-rg"
vnet_rg_name = "MyPackerGroup"
#subnet_name = "test-sas-subnet-a"
subnet_name = "default"
ipconf_name = "sas-dev-ipconfig"
username = "premterraform"
password = "Premterraform@20"
vm_size = "Standard_E64s_v3"


rule_name = ["remote_ssh","remote_metadata"]
rule_description = ["Allow Ssh to sas env","Allow access to metadata server"]
rule_portrange = ["22","8561"]




