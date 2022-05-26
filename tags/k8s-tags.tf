# ===================== #
# Virtual Machines Tags #
# ===================== #
# Tag Categories #


provider "vsphere" {
  user           = var.user_name
  password       = var.password
  vsphere_server = var.vsphere_server_name

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

resource "vsphere_tag_category" "tag-k8s" {    
  name = "k8s"    
  cardinality = "SINGLE"
  description = "Managed by Terraform"
  associable_types = [        
    "VirtualMachine"    
  ]
} 
# Tag Environment Variables #
resource "vsphere_tag" "tag-k8s-workers" {    
  name = "workers"    
  category_id = vsphere_tag_category.tag-k8s.id
  description = "kubernetes ubuntu workers"
} 
resource "vsphere_tag" "tag-k8s-control-plane" {    
  name = "control-plane"    
  category_id = vsphere_tag_category.tag-k8s.id
  description = "kubernetes control plane"
} 
resource "vsphere_tag" "tag-k8s-control-plane-ha" {    
  name = "control-plane-ha"    
  category_id = vsphere_tag_category.tag-k8s.id
  description = "kubernetes control plane HA machine"
} 
