terraform {
  required_version = "> 0.9.0"
}

provider "aws" {
  region = "${var.region}"
}

module "ecs_cluster" {
  source = "./../terraform-modules/ecs-cluster"

  name          = "ecs-example"
  size          = 1
  instance_type = "t2.micro"
  key_pair_name = "${var.key_pair_name}"

  vpc_id     = "${data.aws_vpc.default.id}"
  subnet_ids = ["${data.aws_subnet.default.*.id}"]

  # Allow SSH access from any IP (not recommended for production).
  allow_ssh_from_cidr_blocks = ["0.0.0.0/0"]

  # Allow requests on our container's port from any IP (not recommended for production)
  allow_inbound_ports_and_cidr_blocks = "${map(
    var.container_1_port, "0.0.0.0/0"
  )}"
}

module "container_1" {
  source = "./../terraform-modules/ecs-service"

  name           = "container-1"
  ecs_cluster_id = "${module.ecs_cluster.ecs_cluster_id}"

  image         = "${var.container_1_image}"
  image_version = "${var.container_1_version}"
  cpu           = 1024
  memory        = 768
  desired_count = 1

  container_port = "${var.container_1_port}"
  host_port      = "${var.container_1_port}"
  elb_name       = "${module.container_1_elb.elb_name}"

  num_env_vars = 0

  # if we wanted to use environment variables, we'd add them like this:
  # env_vars = "${map(
  #   "VAR1", "value",
  #   "VAR2", "value"
  # )}"
}

module "container_1_elb" {
  source = "./../terraform-modules/elb"

  name = "container-1-elb"

  vpc_id     = "${data.aws_vpc.default.id}"
  subnet_ids = ["${data.aws_subnet.default.*.id}"]

  instance_port     = "${var.container_1_port}"
  health_check_path = "health"
}
