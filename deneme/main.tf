provider "vsphere" {
  user           = var.user_name
  password       = var.password
  vsphere_server = var.vsphere_server_name

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "LabDC"
}

data "vsphere_datastore_cluster" "datastore_cluster" {
  name          = "LabDSC"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "lun1" {
  name          = "Lab_Lun1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = "k8s"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = "DPortGroup1043"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = "template-ubuntu-20.04"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "vm" {
  name             = "ansible-egitim"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_cluster_id = data.vsphere_datastore_cluster.datastore_cluster.id
  folder           = "k8s"
  num_cpus = 4
  memory   = 8192
  guest_id = data.vsphere_virtual_machine.template.guest_id

  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "ansible-egitim"
        domain    = "anadolu.edu.tr"
      }

        network_interface { }
    }
  }

  provisioner "remote-exec" {
    script = var.create_ssh_folder_script_path

    connection{
      type      = "ssh"
      user      = var.admin_user_name
      password  = var.admin_password
      host      = vsphere_virtual_machine.vm.default_ip_address
    }
  }

  provisioner "file" {

  source      = var.public_key_path
  destination = "~/.ssh/authorized_keys"

  connection{
    type      = "ssh"
    user      = var.admin_user_name
    password  = var.admin_password
    host      = vsphere_virtual_machine.vm.default_ip_address
  }
 }

 provisioner "file" {

  source      = var.script_file_path_zsh
  destination = "/tmp/install_oh_my_zsh.sh"

  connection{
    type      = "ssh"
    user      = var.admin_user_name
    password  = var.admin_password
    host      = vsphere_virtual_machine.vm.default_ip_address
  }
 }

  provisioner "file" {

  source      = var.script_file_path_ansible
  destination = "/tmp/install_ansible.sh"

  connection{
    type      = "ssh"
    user      = var.admin_user_name
    password  = var.admin_password
    host      = vsphere_virtual_machine.vm.default_ip_address
  }
 }

 

     provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_oh_my_zsh.sh",
      "chmod +x /tmp/install_ansible.sh",
      "echo ${var.admin_password} | sudo -S /tmp/install_ansible.sh",
      "/tmp/install_oh_my_zsh.sh",
    ]

    connection{
      type      = "ssh"
      user      = var.admin_user_name
      password  = var.admin_password
      host      = vsphere_virtual_machine.vm.default_ip_address
    }
  }

      provisioner "remote-exec" {
    script = var.script_file_path_ssh_agent

    connection{
      type      = "ssh"
      user      = var.admin_user_name
      password  = var.admin_password
      host      = vsphere_virtual_machine.vm.default_ip_address
    }
  }
    provisioner "file" {

    source      = var.private_key_location
    destination = "~/.ssh/privateKeys/ansibleprivatekey"

    connection{
      type      = "ssh"
      user      = var.admin_user_name
      password  = var.admin_password
      host      = vsphere_virtual_machine.vm.default_ip_address
    }
  }

    provisioner "remote-exec" {
    inline = [
      "chmod 700 -R ~/.ssh/privateKeys"
    ]

    connection{
      type      = "ssh"
      user      = var.admin_user_name
      password  = var.admin_password
      host      = vsphere_virtual_machine.vm.default_ip_address
    }
  }
}