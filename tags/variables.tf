variable "admin_user_name"{
    type = string
}

variable "admin_password"{
    type = string
    sensitive = true
}

variable "user_name"{
    type = string
}

variable "password"{
    type = string
}

variable "vsphere_server_name"{
    type = string
}

