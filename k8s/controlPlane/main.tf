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

data "vsphere_tag_category" "tag-k8s" {
  name          = "k8s"
}

data "vsphere_tag" "tag-k8s-control-plane" {    
  name = "control-plane"    
  category_id = data.vsphere_tag_category.tag-k8s.id
} 

data "vsphere_tag" "tag-k8s-control-plane-ha" {    
  name = "control-plane-ha"    
  category_id = data.vsphere_tag_category.tag-k8s.id
} 

resource "vsphere_virtual_machine" "vm" {
  count = var.instance_count
  name             = "k8s-c-plane-${count.index + 1}"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_cluster_id = data.vsphere_datastore_cluster.datastore_cluster.id
  folder           = "k8s"
  num_cpus = 8
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
        host_name = "k8s-c-plane-${count.index + 1}"
        domain    = "anadolu.edu.tr"
      }

         network_interface {
        ipv4_address = "10.43.1.${count.index + 11}"
        ipv4_netmask = 22
      }

      ipv4_gateway = "10.43.0.1"
      dns_server_list = [ "212.175.41.103","193.140.21.38" ]
    }
  }

   tags = [
    #  element(vsphere_virtual_machine.vm.*.name , count.index) == "kube-control-plane-1" ? data.vsphere_tag.tag-k8s-control-plane.id : data.vsphere_tag.tag-k8s-control-plane-ha.id
     count.index == 0 ? data.vsphere_tag.tag-k8s-control-plane.id : data.vsphere_tag.tag-k8s-control-plane-ha.id
    #  vsphere_virtual_machine.vm[count.index].name == "kube-control-plane-1" ? data.vsphere_tag.tag-k8s-control-plane.id : data.vsphere_tag.tag-k8s-control-plane-ha.id
   ]

     provisioner "remote-exec" {
        inline = [
        "echo ${var.admin_password} | sudo -S adduser --disabled-password --gecos '' k8s-admin",
        "sudo mkdir -p /home/k8s-admin/.ssh",
        "sudo touch /home/k8s-admin/.ssh/authorized_keys",
        "sudo echo '${var.k8s_user_publickey}' > authorized_keys",
        "sudo mv authorized_keys /home/k8s-admin/.ssh",
        "sudo chown -R k8s-admin:k8s-admin /home/k8s-admin/.ssh",
        "sudo chmod 700 /home/k8s-admin/.ssh",
        "sudo chmod 600 /home/k8s-admin/.ssh/authorized_keys",
        "echo 'k8s-admin ALL=(ALL) NOPASSWD: ALL' | sudo tee -a /etc/sudoers"
   ]

     connection{
      type      = "ssh"
      user      = var.admin_user_name
      password  = var.admin_password
      host      = self.default_ip_address
    }
  }
}