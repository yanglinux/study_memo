variable "images" {
    default = {
        ap-southeast-1 = "ami-68d8e93a"
        ap-northeast-1 = "ami-56d4ad31"
    }
}

provider "aws" {
    region = "ap-northeast-1"
}

resource "aws_vpc" "wordpressVPC" {
    cidr_block = "10.10.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "false"
    tags {
        Name = "wordpressVPC"
    }
}

resource "aws_internet_gateway" "wordpressGW" {
    vpc_id = "${aws_vpc.wordpressVPC.id}"
#    depends_on = "${aws_vpc.wordpressVPC}"
}

resource "aws_subnet" "public-wordpress" {
    vpc_id = "${aws_vpc.wordpressVPC.id}"
    cidr_block = "10.10.1.0/24"
    availability_zone = "ap-northeast-1a"
}

resource "aws_subnet" "private-wordpress" {
    vpc_id = "${aws_vpc.wordpressVPC.id}"
    cidr_block = "10.10.2.0/24"
    availability_zone = "ap-northeast-1c"
}

resource "aws_route_table" "public_route" {
    vpc_id = "${aws_vpc.wordpressVPC.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.wordpressGW.id}"
    }
}

resource "aws_route_table_association" "public-wordpress" {
    subnet_id = "${aws_subnet.public-wordpress.id}"
    route_table_id = "${aws_route_table.public_route.id}"
}

resource "aws_security_group" "wordpress_SecturiyG" {
    name = "admin"
    description = "Allow SSH ,web80 inbound traffic"
    vpc_id = "${aws_vpc.wordpressVPC.id}"
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

resource "aws_instance" "wordpress-instance" {
    ami = "${lookup(var.images, "ap-northeast-1" )}"
    instance_type = "t2.micro"
#    key_name = "lintest"
    vpc_security_group_ids = [
        "${aws_security_group.wordpress_SecturiyG.id}"
    ]
    subnet_id = "${aws_subnet.public-wordpress.id}"
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
        Name = "wordpress-instance"
    }
}

output "public ip of wordpress-instance" {
    value = "${aws_instance.wordpress-instance.public_ip}"
}

resource "aws_db_subnet_group" "wordpressdb-subnet"{
    name = "wordpressdb-subnet"
    description = "wordpress db subnet"
    subnet_ids = ["${aws_subnet.public-wordpress.id}", "${aws_subnet.private-wordpress.id}"]
}

resource "aws_security_group" "wordpressdb-sg" {
    name = "wordpressdb-sg"
    description = "wordpress db"
    vpc_id = "${aws_vpc.wordpressVPC.id}"
    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["10.10.0.0/16"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

#resource "aws_db_parameter_group" "wordpressdbpg"{
#    name = "wordpressdbpg"
#    family = "mariadb10.0.24"
#    description = "for wordpress"

#    parameter {
#        name = "log_min_duration_statement"
#        value = 100
#    }
#}

resource "aws_db_instance" "wordpressdb-instance"{
    identifier = "wordpressdb"
    allocated_storage = 100
    engine = "${var.rds_engine}"
    engine_version = "${var.rds_engine_version}"
    instance_class = "${var.rds_instance_class}"
    name = "${var.database_name}"
    username = "${var.db_username}"
    password = "${var.db_password}"
    db_subnet_group_name = "${aws_db_subnet_group.wordpressdb-subnet.name}"
    vpc_security_group_ids = ["${aws_security_group.wordpressdb-sg.id}"]
    #parameter_group_name = "${aws_db_parameter_group.wordpressdbpg.name}"
    multi_az = false
    backup_retention_period = "7"
    backup_window = "01:00-01:30"
    apply_immediately = "true"
    auto_minor_version_upgrade = false
}

output "wordpressdb" {
    value = "${aws_db_instance.wordpressdb-instance.address}"
}
