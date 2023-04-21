packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name                    = "Packer-Image-EC2-AWS"
  instance_type               = "t2.micro"
  region                      = "us-east-1"
  source_ami                  = "ami-007855ac798b5175e"
  ssh_username                = "ubuntu"
  security_group_id           = "sg-04dfaf5c570feb623"
  vpc_id                      = "vpc-09ba21db81cc872f9"
  subnet_id                   = "subnet-07fc75ae478073405"
  communicator                = "ssh"
  associate_public_ip_address = true
  temporary_key_pair_type     = "ed25519"

    tags = {
      Name = "Packer_Image_EC2_AWS"
    }
}

build {
  sources = ["source.amazon-ebs.ubuntu"]
}
