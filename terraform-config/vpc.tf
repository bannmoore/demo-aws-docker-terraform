data "aws_vpc" "default" {
  default = true
}

data "aws_availability_zones" "available" {}

data "aws_subnet" "default" {
  count             = "${min(length(data.aws_availability_zones.available.names), 3)}"
  default_for_az    = true
  vpc_id            = "${data.aws_vpc.default.id}"
  availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"
}
