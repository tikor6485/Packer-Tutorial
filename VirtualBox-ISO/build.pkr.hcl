# Define the source for building the VM
source "virtualbox-iso" "ubuntu" {
  
  # Specify the checksum for the Ubuntu ISO file
  iso_checksum         = "eecb9c8160cdb08adf0c2f17daa1d403f5a55f14a856a5973f32f267eb9db039"   
  # Specify the URL of the Ubuntu ISO file
  iso_url              = "http://releases.ubuntu.com/xenial/ubuntu-16.04.6-desktop-i386.iso"  
  communicator         = "ssh"  # Specify the communication method to be used with the VM  
  # Specify the username and password to be used for SSH login
  ssh_username         = "admin"
  ssh_password         = "PassWord"    
  ssh_wait_timeout     = "1500s" # Specify the maximum time to wait for SSH connection  
  cpus                 = 2
  memory               = 2048
  disk_size            = "20000"
  hard_drive_interface = "sata" 
  boot_wait            = "30s"
  boot_command         = ["<tab> text ks=hd:/dev/fd0:ks.cfg ksdevice=eth0 net.ifnames=0 biosdevname=0<enter><wait>"]
  floppy_files         = ["/home/tirdad/Packer/Packer_Tutorial/VirtualBox-ISO/http/preseed.cfg"]
  guest_additions_mode = "attach"
  http_directory       = "http"
  guest_additions_path = "/home/tirdad/Downloads/VBoxGuestAdditions.iso"
  shutdown_command     = "echo 'packer' | sudo -S shutdown -P now"  # Specify the command to be executed for shutting down the VM    
  format               = "ova"  # Specify the format of the output file
}

# Build the VM using the source defined above
build {
  sources = ["source.virtualbox-iso.ubuntu"]
  
  # Install Apache web server on the VM using shell provisioner
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y apache2",
      "sudo ufw allow 'Apache'",
      "sudo systemctl enable apache2",
      "sudo systemctl start apache2"
    ]
  }
}
