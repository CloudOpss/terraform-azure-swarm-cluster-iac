resource "azurerm_virtual_machine" "tf-worker-vm" {
  count = "${var.numberOfWorkers}"

  name                = "worker-vm-${count.index}"
  location            = "${azurerm_resource_group.tf-swarm-cluster-resourcegroup.location}"
  resource_group_name = "${azurerm_resource_group.tf-swarm-cluster-resourcegroup.name}"

  network_interface_ids = ["${azurerm_network_interface.tf-worker-nic.*.id[count.index]}"]
  availability_set_id   = "${azurerm_availability_set.tf-cluster-availability-set.id}"

  vm_size = "${var.workerVmSize}"

  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "worker-vm-os-disk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.tf-worker-data-disk.*.name[count.index]}"
    managed_disk_id = "${azurerm_managed_disk.tf-worker-data-disk.*.id[count.index]}"
    disk_size_gb    = "${azurerm_managed_disk.tf-worker-data-disk.*.disk_size_gb[count.index]}"
    create_option   = "Attach"
    lun             = 0
  }

  os_profile {
    computer_name  = "worker-${count.index}"
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = "${file("${path.module}/ssh/azure-test-rsa.pub")}"
    }
  }

  # the default connection config for provisioners
  connection {
    type        = "ssh"
    user        = "azureuser"
    private_key = "${file("${path.module}/ssh/azure-test-rsa")}"
    host        = "${azurerm_public_ip.tf-worker-public-ip.*.ip_address[count.index]}"
  }

  # setup VM
  provisioner "file" {
    source      = "scripts/docker-install.sh"
    destination = "/tmp/docker-install.sh"
  }

  # provisioner "file" {
  #   source      = "scripts/worker-init.sh"
  #   destination = "/tmp/worker-init.sh"
  # }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/docker-install.sh",
      "/tmp/docker-install.sh",
    ]
  }
  # drain worker on destroy event (from manager)
  provisioner "remote-exec" {
    when = "destroy"

    inline = [
      "docker node update --availability drain ${self.name}",
    ]

    on_failure = "continue"

    connection {
      type        = "ssh"
      user        = "azureuser"
      private_key = "${file("${path.module}/ssh/azure-test-rsa")}"
      host        = "${azurerm_public_ip.tf-manager-public-ip.0.ip_address}"
    }
  }
  # leave swarm on destroy event
  provisioner "remote-exec" {
    when = "destroy"

    inline = [
      "docker swarm leave",
    ]

    on_failure = "continue"
  }
  # remove node on destroy event (from manager)
  provisioner "remote-exec" {
    when = "destroy"

    inline = [
      "docker node rm --force ${self.name}",
    ]

    on_failure = "continue"

    connection {
      type        = "ssh"
      user        = "azureuser"
      private_key = "${file("${path.module}/ssh/azure-test-rsa")}"
      host        = "${azurerm_public_ip.tf-worker-public-ip.*.ip_address[count.index]}"
    }
  }
  tags {
    environment = "${var.env}"
  }
}
