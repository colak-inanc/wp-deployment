# VPC
resource "huaweicloud_vpc" "vpc" {
  name = "inanc-vpc"
  cidr = "10.10.0.0/16"
}

# Subnet
resource "huaweicloud_vpc_subnet" "subnet" {
  name       = "test-subnet"
  vpc_id     = huaweicloud_vpc.vpc.id
  cidr       = "10.10.0.0/24"
  gateway_ip = "10.10.0.1"
}

# Security Group
resource "huaweicloud_networking_secgroup" "secgroup" {
  name                 = "test-secgroup"
  description          = ""
  delete_default_rules = true
}

# Security Group Rule - HTTP
resource "huaweicloud_networking_secgroup_rule" "secgroup_rule_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
}

resource "huaweicloud_networking_secgroup_rule" "secgroup_rule_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
}


