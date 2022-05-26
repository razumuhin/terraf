variable "public_key_path"{
    type = string
}

variable "create_ssh_folder_script_path"{
    type = string
}

variable "admin_user_name"{
    type = string
    sensitive = true
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

variable "private_key_location"{
    type = string
}

variable "script_file_path_ssh_agent" {
  type = string
}

variable "script_file_path_ansible" {
  type = string
}

variable "script_file_path_zsh" {
  type = string
}