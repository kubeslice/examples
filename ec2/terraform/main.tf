provider "aws" {
  region = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "ubuntu-ec2" {
  ami                    = data.aws_ami.ubuntu.image_id
  instance_type          = "t2.xlarge"
  key_name               = var.key_pair
  vpc_security_group_ids = [aws_security_group.sgubuntu.id]

  root_block_device {
    # device_name = "/dev/xvda"
    volume_size = 30
  }

  tags = {
    Name = "kind-test"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.key_pair_file)
    host        = self.public_ip
  }

  # provisioner "file" {
  #   source      = "templates/provisioner.sh"
  #   destination = "/tmp/provisioner.sh"
  # }

  # provisioner "remote-exec" {
  #   inline = [
  #     "chmod +x /tmp/provisioner.sh",
  #     "/tmp/provisioner.sh",
  #   ]
  # }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "git clone https://github.com/kubeslice/examples.git /tmp/examples",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "cd /tmp/examples",
      "git checkout ec2",
      "chmod +x /tmp/examples/ec2/install_dependencies.sh",    
      "cd /tmp/examples/ec2; ./install_dependencies.sh",
      "sudo usermod -aG docker $USER",
   #   "newgrp docker",
      "sleep 10",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "cd /tmp/examples",
      "git checkout ec2",
      "chmod +x /tmp/examples/kind/kind.sh",    
      "cd /tmp/examples/kind; ./kind.sh",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "cd /tmp/examples",
      "git checkout ec2",
      "chmod +x /tmp/examples/kind/bookinfo/bookinfo.sh",    
      "cd /tmp/examples/kind/bookinfo; ./bookinfo.sh",
    ]
  }
}

resource "aws_security_group" "sgubuntu" {
  name = "sgubuntu"

  ingress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "value"
    from_port        = 22
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 22
  }]

  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "value"
    from_port        = 0
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = []
    protocol         = "-1"
    security_groups  = []
    self             = false
    to_port          = 0
  }]
}

output "test" {
  value = data.aws_ami.ubuntu.image_id
}
