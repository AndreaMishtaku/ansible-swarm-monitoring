packer {
  required_plugins {
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
    virtualbox = {
      source  = "github.com/hashicorp/virtualbox"
      version = "~> 1"
    }
  }
}

variable "os_type" {
  description = "Operating system type: 'windows', 'linux', etc."
  default = "windows"
}

locals {
  is_windows = var.os_type == "windows"
}

source "virtualbox-iso" "VCC-ubuntu-2204" {
  // VM Info:
  vm_name       = "VCC-ubuntu-2204"
  guest_os_type = "Ubuntu_64"
  headless      = false

  // Virtual Hardware Specs
  memory        = 2048
  cpus          = 2
  disk_size     = 30720

  // ISO details
  iso_checksum            = "sha256:a4acfda10b18da50e2ec50ccaf860d7f20b389df8765611142305c0e911d16fd"
  iso_urls                = local.is_windows ? [
    "${path.cwd}\\ubuntu-22.04.3-live-server-amd64.iso"] : [
    "file:${path.cwd}/ubuntu-22.04.3-live-server-amd64.iso",
  ]
  output_directory        = "./build"
  http_directory          = "http"
  ssh_password            = "vagrant"
  ssh_port                = 22
  ssh_username            = "vagrant"
  ssh_wait_timeout        = "1800s"
  vboxmanage              = [
   ["modifyvm", "{{ .Name }}", "--graphicscontroller", "vmsvga"],
   ["modifyvm", "{{ .Name }}", "--audiocontroller", "ac97"],
   ["modifyvm", "{{.Name}}", "--nat-localhostreachable1", "on"],
  ]

  boot_wait = "5s"
  boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall<wait>",
    " net.ifnames=0 biosdevname=0",
    " cloud-config-url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/user-data<wait>",
    " ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot",
    "<enter>"
  ]

  shutdown_command = "echo 'vagrant' |sudo -S shutdown -P now"
}  

build {

  sources = [
    "source.virtualbox-iso.VCC-ubuntu-2204"
  ]

  provisioner "shell" {
    execute_command = "echo 'vagrant' | {{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    script          = "scripts/install-vbox-guest.sh"
  }

  provisioner "shell" {
    execute_command = "echo 'vagrant' | {{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    script          = "scripts/setup.sh"
  }

  provisioner "shell" {
    execute_command = "echo 'vagrant' | {{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    script          = "scripts/cleanup.sh"
  }

  post-processor "vagrant" {
    compression_level   = 9
    output              = "build/{{ .Provider }}-VCCubuntu2204.box"
    keep_input_artifact = true
  }

}
