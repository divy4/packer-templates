
variable "acceleration_2d" { type = string }
variable "acceleration_3d" { type = string }
variable "audio" { type = string }
variable "bios_boot_menu" { type = string }
variable "clipboard" { type = string }
variable "cpus" { type = number }
variable "disk_size_mb" { type = number }
variable "drag_and_drop" { type = string }
variable "firmware" { type = string }
variable "first_boot_wait" { type = string }
variable "format" { type = string }
variable "guest_additions_path" { type = string }
variable "iso_checksum" { type = string }
variable "iso_url" { type = string }
variable "memory" { type = number }
variable "mouse" { type = string }
variable "name" { type = string }
variable "post_shutdown_delay" { type = string }
variable "proxy" { type = string }
variable "root_password" { type = string }
variable "seed_usb_serial" { type = string }
variable "shutdown_timeout" { type = string }
variable "ssh_password" { type = string }
variable "ssh_username" { type = string }
variable "vm_base_directory" { type = string }
variable "vram" { type = number }

source "virtualbox-iso" "this" {
  # Hardware
  vm_name                  = var.name
  cpus                     = var.cpus
  memory                   = var.memory
  disk_size                = var.disk_size_mb
  hard_drive_discard       = true
  hard_drive_interface     = "sata"
  hard_drive_nonrotational = true
  guest_os_type            = "ArchLinux_64"

  # Installation iso
  iso_url       = var.iso_url
  iso_checksum  = var.iso_checksum
  iso_interface = "sata"

  # Startup / shutdown
  boot_command = [
    "passwd<enter><wait>",
    "${var.root_password}<enter><wait>",
    "${var.root_password}<enter><wait>",
    "systemctl start sshd<enter><wait>"
  ]
  boot_wait           = var.first_boot_wait
  post_shutdown_delay = var.post_shutdown_delay
  shutdown_command    = "shutdown now"
  shutdown_timeout    = var.shutdown_timeout

  # Connection
  ssh_username = var.ssh_username
  ssh_password = var.ssh_password

  # Export
  export_opts      = ["--manifest"]
  format           = var.format
  output_directory = "${var.vm_base_directory}/${var.name}"

  # Extra VirtualBox settings
  vboxmanage = [
    [
      "modifyvm",
      "{{ .Name }}",
      # Audio
      "--audio-driver", var.audio,
      "--audiocontroller", "ac97",
      # Video
      "--accelerate2dvideo", "${var.acceleration_2d}",
      "--accelerate3d", "${var.acceleration_3d}",
      "--graphicscontroller", "vboxsvga",
      "--vram", var.vram,
      # Bios
      "--biosbootmenu", var.bios_boot_menu,
      "--boot1", "disk",
      "--boot2", "dvd",
      "--boot3", "none",
      "--boot4", "none",
      "--firmware", var.firmware,
      # Clipboard
      "--clipboard-mode", var.clipboard,
      "--draganddrop", var.drag_and_drop,
      # Hardware
      "--cpuexecutioncap", "100",
      "--mouse", var.mouse,
      "--nested-hw-virt", "on",
      "--rtcuseutc", "on",
      "--usb", "on",
      "--usbehci", "on",
      "--vrde", "off",
      # Network
      "--natpf1", "SSH,tcp,,22,,22"
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
    ],
    [
      "usbfilter",
      "add",
      "0",
      "--target", "{{ .Name }}",
      "--name", "Seed drive",
      "--serialnumber", var.seed_usb_serial
    ]
  ]
}

build {
  sources = ["source.virtualbox-iso.this"]

  provisioner "file" {
    destination = "/usr/bin/rankmirrors"
    source      = "${path.root}/../../provisioners/file/rankmirrors"
  }

  provisioner "shell" {
    environment_vars = [
      "ftp_proxy=${var.proxy}",
      "http_proxy=${var.proxy}",
      "https_proxy=${var.proxy}",
      "HOSTNAME=${var.name}",
      "MEMORY=${var.memory}",
      "NETWORK_INTERFACE=enp0s3",
      "ROOT_PASSWORD=${var.root_password}"
    ]
    script = "${path.root}/../../provisioners/shell/bootstrap_arch.sh"
  }

  provisioner "shell-local" {
    command = "vboxmanage controlvm \"${var.name}\" acpipowerbutton"
  }

  provisioner "shell-local" {
    command      = "vboxmanage storageattach \"${var.name}\" --storagectl \"SATA Controller\" --port 15 --medium emptydrive"
    pause_before = "10s"
  }

  provisioner "shell-local" {
    command      = "vboxmanage startvm \"${var.name}\""
    pause_before = "5s"
  }

  provisioner "shell" {
    environment_vars = [
      "ftp_proxy=${var.proxy}",
      "GUEST_ADDITIONS_PATH=${var.guest_additions_path}",
      "http_proxy=${var.proxy}",
      "https_proxy=${var.proxy}"
    ]
    script = "${path.root}/../../provisioners/shell/install_virtualbox_guest_additions.sh"
  }
}
