provider "aws" {
  profile = "sharan"
  region  = "us-east-2"
}
resource "aws_instance" "k8s-master" {
 // count         = 2
  //ami           = "ami-00399ec92321828f5"
  ami="ami-00dfe2c7ce89a450b"
  instance_type = "t2.micro"
  # user_data = <<-EOF
  # 		#!/bin/bash
  # 		sudo apt-get update
  # 		sudo apt-get install nginx -y
  # 		sudo systemctl enable nginx
  # 		sudo systemctl start nginx
  #   		EOF
  subnet_id              = aws_subnet.subnet_public.id
  vpc_security_group_ids = [aws_security_group.sg_22.id]
  key_name               = aws_key_pair.rsakey.id
  tags = {
    Name = "Master Node"
  }
}

resource "aws_instance" "k8s-workers" {
  count         = 2
  # ami           = "ami-00399ec92321828f5"
  ami="ami-00dfe2c7ce89a450b"
  instance_type = "t2.micro"
  # user_data = <<-EOF
  # 		#!/bin/bash
  # 		sudo apt-get update
  # 		sudo apt-get install nginx -y
  # 		sudo systemctl enable nginx
  # 		sudo systemctl start nginx
  #   		EOF
  subnet_id              = aws_subnet.subnet_public.id
  vpc_security_group_ids = [aws_security_group.sg_22.id]
  key_name               = aws_key_pair.rsakey.id
  tags = {
    Name = "Worker Node - $[count.index]"
  }
}

resource "aws_key_pair" "rsakey" {
  public_key = file("/home/sharas/.ssh/id_rsa.pub")
}

# resource "aws_security_group" "secgrp"{
# 	name = "secgrp"
# 	description = "Allow access from the internet"
# 	ingress{
# 		from_port=0
# 		to_port=0
# 		protocol="-1"
# 		cidr_blocks=["0.0.0.0/0"]
# 	}
# 	egress{
# 		from_port=0
# 		to_port=0
# 		protocol="-1"
# 		cidr_blocks=["0.0.0.0/0"]
# 	}
# }

# resource "aws_default_vpc" "default" {
#   tags = {
#     Name = "Default VPC"
#   }
# }

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Environment = var.environment_tag
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Environment = var.environment_tag
  }
}

resource "aws_subnet" "subnet_public" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.cidr_subnet
  map_public_ip_on_launch = "true"
  availability_zone       = var.availability_zone
  tags = {
    Environment = var.environment_tag
  }
}

resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Environment = var.environment_tag
  }
}

resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.rtb_public.id
}

resource "aws_security_group" "sg_22" {
  name   = "sg_22"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Environment = var.environment_tag
  }
}

output "master_ip" {
  value = aws_instance.k8s-master.*.public_ip
}
output "worker_ips" {
  value = aws_instance.k8s-workers.*.public_ip
}
