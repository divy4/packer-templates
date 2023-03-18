
variable "ansible_playbook" {
  type = string
}

variable "audio" {
  type = string
}

variable "cpus" {
  type = number
}

variable "memory" {
  type = number
}

variable "name" {
  type = string
}

variable "parent_template" {
  type = string
}

variable "proxy" {
  type = string
}

variable "ssh_password" {
  type = string
}

variable "ssh_username" {
  type = string
}

variable "swap" {
  type = string
}

variable "vm_base_directory" {
  type = string
}

variable "vram" {
  type = number
}

source "virtualbox-ovf" "this" {
  # Hardware
  vm_name              = var.name
  guest_additions_mode = "disable"
  headless             = true

  # Startup / shutdown
  shutdown_command = "echo '${var.ssh_password}' | sudo -S shutdown -P now"

  # Connection
  ssh_password = var.ssh_password
  ssh_username = var.ssh_username

  # Import / export
  source_path      = "${var.vm_base_directory}/${var.parent_template}/${var.parent_template}.ovf"
  import_flags     = ["--basefolder", var.vm_base_directory]
  export_opts      = ["--manifest"]
  output_directory = "${var.vm_base_directory}/${var.name}"

  # Extra VirtualBox settings
  vboxmanage = [
    [
      "modifyvm",
      "{{ .Name }}",
      "--audio",
      var.audio,
      "--cpus",
      var.cpus,
      "--memory",
      var.memory,
      "--vram",
      var.vram,
      "--vrde",
      "off"
    ],
    [
      "setextradata",
      "global",
      "GUI/SuppressMessages",
      "all"
    ],
    [
      "setextradata",
      "{{ .Name }}",
      "GUI/ShowMiniToolBar",
      "false"
    ]
  ]
}

build {
  sources = ["source.virtualbox-ovf.this"]

  provisioner "shell" {
    environment_vars = [
      "HOSTNAME=${var.name}"
    ]
    execute_command = "echo '${var.ssh_password}' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "${path.root}/../../provisioners/shell/set_hostname.sh"
  }

  provisioner "shell" {
    environment_vars = [
      "SWAP=${var.swap}",
      "SWAP_SIZE=${var.memory}"
    ]
    execute_command = "echo '${var.ssh_password}' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "${path.root}/../../provisioners/shell/configure_swap.sh"
  }

  provisioner "file" {
    destination = "/tmp"
    source      = "${path.root}/../../provisioners/ansible"
  }

  provisioner "shell" {
    environment_vars = [
      "ftp_proxy=${var.proxy}",
      "http_proxy=${var.proxy}",
      "https_proxy=${var.proxy}",
      "PLAYBOOK=${var.ansible_playbook}",
      "SSH_PASSWORD=${var.ssh_password}"
    ]
    script = "${path.root}/../../provisioners/shell/install_and_run_ansible.sh"
  }

}
