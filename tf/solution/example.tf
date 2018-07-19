# supply on command line w/ envvar TF_VAR_ssh_key_pub
# e.g.
# TF_VAR_ssh_key_pub=`cat ~/.ssh/id_rsa.pub` terraform apply
# then ssh to your instance:
# ssh ubuntu@`aws ec2 describe-instances | jq -r '.Reservations[].Instances[] | select(.State.Name != "terminated") | .PublicIpAddress'`
variable ssh_key_pub {}

variable region {
  default = "us-east-1"
}

# this is handy
# https://cloud-images.ubuntu.com/locator/ec2/
variable "amis" {
  type = "map"
  default = {
    # ubuntu 16.04 amd64, hvm:ebs-ssd
    "us-east-1" = "ami-a4dc46db"
    "us-west-1" = "ami-8d948ced"
    "ap-northeast-1" = "ami-48a45937"
    "sa-east-1" = "ami-67fca30b"
    "ap-southeast-1" = "ami-81cefcfd"
    "ca-central-1" = "ami-7e21a11a"
    "ap-south-1" = "ami-41e9c52e"
    "eu-central-1" = "ami-c7e0c82c"
    "eu-west-1" = "ami-58d7e821"
    "cn-north-1" = "ami-b117c9dc"
    "cn-northwest-1" = "ami-39b8ac5b"
    "us-gov-west-1" = "ami-0661f767"
    "ap-northeast-2" = "ami-f030989e"
    "ap-southeast-2" = "ami-963cecf4"
    "us-west-2" = "ami-db710fa3"
    "us-east-2" = "ami-6a003c0f"
    "eu-west-2" = "ami-5daa463a"
    "eu-west-3" = "ami-1960d164"
  }
}

provider "aws" {
  /*
  inherit from $HOME/.aws/credentials instead...
  access_key = "ACCESS_KEY_HERE"
  secret_key = "SECRET_KEY_HERE"
  */
  region = "${var.region}"
  version = "~> 1.7"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.example.id}"
}

resource "aws_route" "route_to_internet" {
  route_table_id = "${aws_vpc.example.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.igw.id}"
}

resource "aws_subnet" "public" {
  cidr_block = "10.0.0.0/20"
  vpc_id = "${aws_vpc.example.id}"
}

resource "aws_key_pair" "keypair" {
  key_name = "mbpro"
  public_key = "${var.ssh_key_pub}"
}

resource "aws_instance" "example" {
  ami = "${lookup(var.amis, var.region)}"
  instance_type = "t2.micro"
  key_name = "mbpro"
  vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}"]
  subnet_id = "${aws_subnet.public.id}"

  provisioner "local-exec" {
    # TODO: I don't know why, but this ip address is NOT right.
    command = "rm -f ip_address.txt && echo ${aws_instance.example.public_ip} > ip_address.txt"
  }

}

resource "aws_eip" "ip" {
  instance = "${aws_instance.example.id}"
  vpc = true
}

resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  description = "Allow inbound ssh traffic"
  vpc_id = "${aws_vpc.example.id}"

  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow All for egress, see:
  # https://www.terraform.io/docs/providers/aws/r/security_group.html#security_groups-1
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
