variable "images" {
    default = {
        ap-southeast-1 = "ami-68d8e93a"
        ap-northeast-1 = "ami-56d4ad31"
    }
}

provider "aws" {
    region = "ap-northeast-1"
}

resource "aws_vpc" "terraformVPC" {
    cidr_block = "10.10.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "false"
    tags {
        Name = "terraformVPC"
    }
}

resource "aws_internet_gateway" "terraformGW" {
    vpc_id = "${aws_vpc.terraformVPC.id}"
#    depends_on = "${aws_vpc.terraformVPC}"
}

resource "aws_subnet" "public-terraform" {
    vpc_id = "${aws_vpc.terraformVPC.id}"
    cidr_block = "10.10.1.0/24"
    availability_zone = "ap-northeast-1a"
}

resource "aws_route_table" "public_route" {
    vpc_id = "${aws_vpc.terraformVPC.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.terraformGW.id}"
    }
}

resource "aws_route_table_association" "public-terraform" {
    subnet_id = "${aws_subnet.public-terraform.id}"
    route_table_id = "${aws_route_table.public_route.id}"
}

resource "aws_security_group" "admin_terraform" {
    name = "admin"
    description = "Allow SSH ,web80 inbound traffic"
    vpc_id = "${aws_vpc.terraformVPC.id}"
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "terraform-test" {
    ami = "${lookup(var.images, "ap-northeast-1" )}"
    instance_type = "t2.micro"
#    key_name = "lintest"
    vpc_security_group_ids = [
        "${aws_security_group.admin_terraform.id}"
    ]
    subnet_id = "${aws_subnet.public-terraform.id}"
    associate_public_ip_address = "true"
    root_block_device = {
        volume_type = "gp2"
        volume_size = "10"
    }
    ebs_block_device = {
        device_name = "/dev/sdf"
        volume_type = "gp2"
        volume_size = "5"
    }
    tags {
        Name = "terraformtest"
    }
}

output "public ip of terraformtest" {
    value = "${aws_instance.terraform-test.public_ip}"
}
