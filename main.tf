terraform {
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = "1.73.0"
    }
  }
}

data "huaweicloud_images_image" "ubuntu2204" {
  name        = "Ubuntu 22.04 server 64bit"
  most_recent = true
}

data "huaweicloud_availability_zones" "myaz" {}

data "huaweicloud_compute_flavors" "myflavor" {
  availability_zone = data.huaweicloud_availability_zones.myaz.names[0]
  cpu_core_count    = 2
  memory_size       = 2
}

data "huaweicloud_images_images" "all" {}
output "all_image_names" {
  value = data.huaweicloud_images_images.all.images[*].name
}

resource "huaweicloud_compute_instance" "wordpress" {
  name              = "wordpress-ecs"
  flavor_id         = data.huaweicloud_compute_flavors.myflavor.flavors[0].id
  image_id          = data.huaweicloud_images_image.ubuntu2204.id
  availability_zone = data.huaweicloud_availability_zones.myaz.names[0]


  network {
    uuid = huaweicloud_vpc_subnet.subnet.id
  }

  security_groups = [huaweicloud_networking_secgroup.secgroup.name]
  user_data       = filebase64("userdata.sh")
}

resource "huaweicloud_rds_instance" "wordpress" {
  name                = "wordpress-db"
  flavor              = "rds.mysql.n1.large.4"
  availability_zone   = [
    data.huaweicloud_availability_zones.myaz.names[0],
    data.huaweicloud_availability_zones.myaz.names[1]
  ]           
  ha_replication_mode = "semisync"            

  vpc_id              = huaweicloud_vpc.vpc.id
  subnet_id           = huaweicloud_vpc_subnet.subnet.id

  db {
    type     = "MySQL"
    version  = "8.0"
    port     = 3306
    password = var.db_password
  }

  volume {
    type = "ULTRAHIGH"
    size = 40
  }
  
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
}

resource "huaweicloud_elb_loadbalancer" "wordpress" {
  name              = "wordpress-lb"
  availability_zone = [data.huaweicloud_availability_zones.myaz.names[0]]
  iptype            = "5_bgp"
  vpc_id            = huaweicloud_vpc.vpc.id

  bandwidth_size = 10
  bandwidth_charge_mode = "traffic"
  sharetype              = "PER"
}

resource "huaweicloud_elb_listener" "wordpress" {
  name            = "wordpress-listener"
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = huaweicloud_elb_loadbalancer.wordpress.id
}

resource "huaweicloud_elb_pool" "wordpress" {
  name        = "wordpress-pool"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = huaweicloud_elb_listener.wordpress.id
}

resource "huaweicloud_as_group" "wordpress" {
  scaling_group_name       = "wordpress-asg"
  vpc_id                   = huaweicloud_vpc.vpc.id
  desire_instance_number   = 2
  min_instance_number      = 1
  max_instance_number      = 3

  scaling_configuration_id = var.instance_config_id

  networks {
    id = huaweicloud_vpc_subnet.subnet.id
  }
}


resource "huaweicloud_compute_instance" "wordpress_template" {
  name              = "wordpress-template"
  image_id          = data.huaweicloud_images_image.ubuntu2204.id
  flavor_id         = data.huaweicloud_compute_flavors.myflavor.flavors[0].id
  availability_zone = data.huaweicloud_availability_zones.myaz.names[0]

  admin_pass = var.instance_password

  security_groups = [huaweicloud_networking_secgroup.secgroup.name]

  system_disk_type = "SAS" 
  system_disk_size = 40

  network {
    uuid = huaweicloud_vpc_subnet.subnet.id
  }
}

resource "huaweicloud_as_configuration" "wordpress_conf" {
  scaling_configuration_name = "wordpress-as-conf"

  instance_config {
    flavor = data.huaweicloud_compute_flavors.myflavor.flavors[0].id
    image          = data.huaweicloud_images_image.ubuntu2204.id

    disk {
      size        = 40
      volume_type = "SAS"
      disk_type   = "SYS"
    }

    security_group_ids = [huaweicloud_networking_secgroup.secgroup.id]
    user_data          = filebase64("userdata.sh")
  }
}



