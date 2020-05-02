
provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_instance" "WebServer1" {
  ami = "${lookup(var.aws_amis, var.aws_region,ami-5f709f34)}"
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  vpc_security_group_ids = "${aws_security_group.InstanceSecurity.id}"
  subnet_id = "${aws_subnet.vpcsubnet.id}"
  user_data = "${file("userdata.sh")}"
  tags={
      Name = "MyInstanceName"
  }
}

resource "aws_vpc" "VPC" {
  cidr_block = "${var.VPC_cidr}"
  enable_dns_hostnames = true
  tags{
    Name = "VirtualNetwork"
  }
  
}

resource "aws_subnet" "vpcsubnet" {
  vpc_id = "${aws_vpc.VPC.id}"
  cidr_block = "${var.subnet_cidr}"
  map_public_ip_on_launch = true
  tags{
    Name = "Subnet1" 
  }
}


resource "aws_internet_gateway" "Gateway" {
  vpc_id = "${aws_vpc.VPC.id}"

  tags = {
    Name = "Gateway1"
  }
}

resource "aws_route_table" "RouteTable" {
  vpc_id = "${aws_vpc.VPC.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.Gateway.id}"
  }

  tags = {
    Name = "aws_route_table"
  }
}

resource "aws_route_table_association" "RouteAssociation" {
  subnet_id      = "${aws_subnet.vpcsubnet.id}"
  route_table_id = "${aws_route_table.RouteTable.id}"
}

resource "aws_security_group" "InstanceSecurity" {
  name        = "instance_sg"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.VPC.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "LoadBalancerSG" {
  name        = "elb_sg"
  description = "Used in the terraform"

  vpc_id = "${aws_vpc.VPC.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ensure the VPC has an Internet gateway or this step will fail
  depends_on = ["aws_internet_gateway.Gateway"]
}

resource "aws_elb" "ELB" {
  name = "Loadbalancer"

  # The same availability zone as our instance
  subnets = ["${aws_subnet.vpcsubnet.id}"]

  security_groups = ["${aws_security_group.LoadBalancerSG.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  # The instance is registered automatically

  instances                   = ["${aws_instance.WebServer1.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
}

resource "aws_lb_cookie_stickiness_policy" "ELBStickiness" {
  name                     = "lbpolicy"
  load_balancer            = "${aws_elb.ELB.id}"
  lb_port                  = 80
  cookie_expiration_period = 600
}

