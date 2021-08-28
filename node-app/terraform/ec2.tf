provider "aws" {
    region = "eu-west-2"
}

variable "project_name" {
    description = "Name given to the EC2 instance, security group, and key pair"
}

data "aws_ami" "ubuntu_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_default_vpc" "main" {}

resource "tls_private_key" "deployment" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployment" {
  key_name   = var.project_name
  public_key = tls_private_key.deployment.public_key_openssh
}

resource "local_file" "deployment_key" {
  filename = pathexpand("~/.ssh/${var.project_name}.pem")
  sensitive_content = tls_private_key.deployment.private_key_pem
  file_permission = "600"
}

resource "aws_security_group" "web_security_group" {
  name = var.project_name
  description = "Job scraper web security group"
  vpc_id = aws_default_vpc.main.id

  ingress {
    description = ""
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description = ""
    from_port = 22
    to_port = 22
    protocol = "all"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu_ami.id
  instance_type = "t2.micro"

  key_name      = aws_key_pair.deployment.key_name

  vpc_security_group_ids = [aws_security_group.web_security_group.id]

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 16
  }

  tags = {
    Name = var.project_name
  }
}

resource "local_file" "ansible_inventory" {
  content = templatefile("ansible-inventory.tmpl", {
    ip          = aws_instance.web.public_ip,
    ssh_keyfile = local_file.deployment_key.filename
  })
  filename = "../ansible/inventory.yml"
}

resource "null_resource" "ansible" {
  provisioner "remote-exec" {
    inline = ["sudo apt update", "sudo apt install python3 -y"]

    connection {
      host        = aws_instance.web.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.deployment.private_key_pem
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook ../ansible/remote-setup.yml"
  }
}
