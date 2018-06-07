/**
* Subnets
**/
resource "azurerm_subnet" "tf-admin-subnet" {
  name                      = "admin-subnet"
  resource_group_name       = "${azurerm_resource_group.tf-swarm-cluster-resourcegroup.name}"
  virtual_network_name      = "${azurerm_virtual_network.tf-swarm-cluster-vnet.name}"
  network_security_group_id = "${azurerm_network_security_group.tf-admin-subnet-nsg.id}"

  address_prefix = "10.0.0.0/24"
}

resource "azurerm_subnet" "tf-managers-subnet" {
  name                      = "managers-subnet"
  resource_group_name       = "${azurerm_resource_group.tf-swarm-cluster-resourcegroup.name}"
  virtual_network_name      = "${azurerm_virtual_network.tf-swarm-cluster-vnet.name}"
  network_security_group_id = "${azurerm_network_security_group.tf-manager-subnet-nsg.id}"

  address_prefix = "10.0.1.0/24"
}

resource "azurerm_subnet" "tf-workers-subnet" {
  name                      = "workers-subnet"
  resource_group_name       = "${azurerm_resource_group.tf-swarm-cluster-resourcegroup.name}"
  virtual_network_name      = "${azurerm_virtual_network.tf-swarm-cluster-vnet.name}"
  network_security_group_id = "${azurerm_network_security_group.tf-worker-subnet-nsg.id}"

  address_prefix = "10.0.2.0/24"
}
