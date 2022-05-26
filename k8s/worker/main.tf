provider "vsphere" {
  user           = var.provider_user_name[terraform.workspace]
  password       = var.provider_password[terraform.workspace]
  vsphere_server = var.vsphere_server_name[terraform.workspace]

  # If you have a self-signed cert
  allow_unverified_ssl = true
}
data "vsphere_datacenter" "dc" {
  name = var.datacenter[terraform.workspace]
}

data "vsphere_datastore_cluster" "datastore_cluster" {
  name          = var.datastore_cluster[terraform.workspace]
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "lun1" {
  name          = var.datastore[terraform.workspace]
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.resource_pool[terraform.workspace]
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network[terraform.workspace]
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = "template-ubuntu-20.04"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_tag_category" "tag-k8s" {
  name          = var.k8s_tag_category[terraform.workspace]
}

data "vsphere_tag" "tag-k8s-workers" {    
  name = var.k8s_worker_tag[terraform.workspace]    
  category_id = data.vsphere_tag_category.tag-k8s.id
} 


resource "vsphere_virtual_machine" "vm" {
  count = var.instance_count[terraform.workspace]
  name             = "${var.vm_name_prefix[terraform.workspace]}-${count.index + 1}"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_cluster_id = data.vsphere_datastore_cluster.datastore_cluster.id
  folder           = var.vm_folder[terraform.workspace]
  num_cpus = var.num_of_cpus[terraform.workspace]
  memory   = var.memory_size[terraform.workspace]
  guest_id = data.vsphere_virtual_machine.template.guest_id

  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
    
  }

  disk {
    label            = var.disk_label[terraform.workspace]
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "${var.vm_name_prefix[terraform.workspace]}-${count.index + 1}"
        domain    = var.domain[terraform.workspace]
      }

         network_interface {
        ipv4_address = "${var.ipv4_address_prefix[terraform.workspace]}.${count.index + 21}"
        ipv4_netmask = var.ipv4_net_mask[terraform.workspace]
      }

      ipv4_gateway = var.ipv4_gateway[terraform.workspace]
      dns_server_list = var.dns_server_list[terraform.workspace]
    }
  }

  tags = [
     data.vsphere_tag.tag-k8s-workers.id
   ]

  provisioner "remote-exec" {
       inline = [
        "echo ${var.admin_password[terraform.workspace]} | sudo -S adduser --disabled-password --gecos '' k8s-admin",
        "sudo mkdir -p /home/k8s-admin/.ssh",
        "sudo touch /home/k8s-admin/.ssh/authorized_keys",
        "sudo echo '${var.k8s_user_publickey[terraform.workspace]}' > authorized_keys",
        "sudo mv authorized_keys /home/k8s-admin/.ssh",
        "sudo chown -R k8s-admin:k8s-admin /home/k8s-admin/.ssh",
        "sudo chmod 700 /home/k8s-admin/.ssh",
        "sudo chmod 600 /home/k8s-admin/.ssh/authorized_keys",
        "echo 'k8s-admin ALL=(ALL) NOPASSWD: ALL' | sudo tee -a /etc/sudoers"
   ]

     connection{
      type      = "ssh"
      user      = var.admin_user_name[terraform.workspace]
      password  = var.admin_password[terraform.workspace]
      host      = self.default_ip_address
    }
  }
}