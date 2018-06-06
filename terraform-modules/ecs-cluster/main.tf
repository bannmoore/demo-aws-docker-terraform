# Create an ECS Cluster for our container instances.
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_clusters.html
# https://www.terraform.io/docs/providers/aws/r/ecs_cluster.html
resource "aws_ecs_cluster" "example_cluster" {
  name = "${var.name}"
}

# Create an EC2 Auto Scaling Group to manage the number of container instances in the cluster.
# Notice that `min_size` and `max_size` are the same, which means the cluster will always host
# `var.size` instances.
# https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html
# https://www.terraform.io/docs/providers/aws/r/autoscaling_group.html
resource "aws_autoscaling_group" "ecs_cluster_instances" {
  name                 = "${var.name}"
  min_size             = "${var.size}"
  max_size             = "${var.size}"
  launch_configuration = "${aws_launch_configuration.ecs_instance.name}"
  vpc_zone_identifier  = ["${var.subnet_ids}"]

  tag {
    key                 = "Name"
    value               = "${var.name}"
    propagate_at_launch = true
  }
}

# Get the latest Amazon ECS-Optimized AMI:
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html
# https://www.terraform.io/docs/providers/aws/d/ami.html
data "aws_ami" "ecs" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }
}

# Create a Launch Configuration that will be used by the auto scaling group to launch EC2 instances.
# https://docs.aws.amazon.com/autoscaling/ec2/userguide/LaunchConfiguration.html
# https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
resource "aws_launch_configuration" "ecs_instance" {
  name_prefix          = "${var.name}-"
  instance_type        = "${var.instance_type}"
  key_name             = "${var.key_pair_name}"
  iam_instance_profile = "${aws_iam_instance_profile.ecs_instance.name}"
  security_groups      = ["${aws_security_group.ecs_instance.id}"]
  image_id             = "${data.aws_ami.ecs.id}"

  # This shell script will execute when each EC2 instance boots.
  # It configures the ECS agent's communication with the ECS cluster.
  user_data = <<EOF
    #!/bin/bash
    echo "ECS_CLUSTER=${var.name}" >> /etc/ecs/ecs.config
    EOF

  # When using an auto scaling group, the launch configuration MUST have `create_before_destroy = true`.
  # This also means that we must set it in each resource this one _depends_ on, which is why you'll see
  # it below.
  lifecycle {
    create_before_destroy = true
  }
}

# Create an IAM role for each instance in the cluster.
resource "aws_iam_role" "ecs_instance" {
  name               = "${var.name}"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_instance.json}"

  # Required by the launch configuration
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "ecs_instance" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_instance_profile" "ecs_instance" {
  name = "${var.name}"
  role = "${aws_iam_role.ecs_instance.name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "ecs_cluster_permissions" {
  name   = "ecs-cluster-permissions"
  role   = "${aws_iam_role.ecs_instance.id}"
  policy = "${data.aws_iam_policy_document.ecs_cluster_permissions.json}"
}

data "aws_iam_policy_document" "ecs_cluster_permissions" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ecs:CreateCluster",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:Submit*",
    ]
  }
}

resource "aws_security_group" "ecs_instance" {
  name        = "${var.name}"
  description = "Security group for the EC2 instances in the ECS cluster ${var.name}"
  vpc_id      = "${var.vpc_id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "all_outbound_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ecs_instance.id}"
}

resource "aws_security_group_rule" "all_inbound_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${var.allow_ssh_from_cidr_blocks}"]
  security_group_id = "${aws_security_group.ecs_instance.id}"
}

resource "aws_security_group_rule" "all_inbound_ports" {
  count = "${length(var.allow_inbound_ports_and_cidr_blocks)}"

  type              = "ingress"
  from_port         = "${element(keys(var.allow_inbound_ports_and_cidr_blocks), count.index)}"
  to_port           = "${element(keys(var.allow_inbound_ports_and_cidr_blocks), count.index)}"
  protocol          = "tcp"
  cidr_blocks       = ["${lookup(var.allow_inbound_ports_and_cidr_blocks, element(keys(var.allow_inbound_ports_and_cidr_blocks), count.index))}"]
  security_group_id = "${aws_security_group.ecs_instance.id}"
}
