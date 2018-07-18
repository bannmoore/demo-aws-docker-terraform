# Docker / Terraform Setup for AWS

Note: This repo was adapted from [infrastructure-as-code-talk](https://github.com/brikis98/infrastructure-as-code-talk)

## Using this Repository

Prerequisites:
- An AWS account with an access key and secret access key
  - If you use an IAM user, make sure it has permissions on EC2, ECS, and IAM
- Docker cloud login (if you want to use a different Docker image)

Before attempting any `terraform` commands, make sure your access keys have been provided as environment variables:

```sh
export AWS_ACCESS_KEY_ID=MY_KEY
export AWS_SECRET_ACCESS_KEY=MY_SECRET_KEY
```

## Using a Different Docker Image

For this to work, the docker image / version must be publicly available on the Docker cloud. This repo contains `container-1`, which runs a very basic node server. The container is published as `bann/container-1:local` so that it can be used for this demo, but feel free to modify the docker definition here and practice publishing your own version.


To use a different image, change these values in `terraform-config/vars.tf`:

```
variable "container_1_image" {
  description = "The name of the Docker image to deploy for the Sinatra backend (e.g. gruntwork/container-1-backend)"
  default     = "bann/container-1"
}

variable "container_1_version" {
  description = "The version (i.e. tag) of the Docker container to deploy for the Sinatra backend (e.g. latest, 12345)"
  default     = "local"
}
```

## Setting up Terraform

This will set up the AWS plugin and allow us to use the other commands.

```sh
cd terraform-config
terraform init
```

Once that's done, view the changes Terraform will make as a dry run:

```sh
terraform plan
```

## Send Infrastructure to AWS

Finally, launch the configuration in AWS:

```
terraform apply
```

If all goes well, Terraform will output the URL:

```txt
Apply complete! Resources: 18 added, 0 changed, 0 destroyed.

Outputs:

container_1_url = http://container-1-elb-11111.us-east-1.elb.amazonaws.com
```

Open the [EC2 Dashboard](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Instances:sort=instanceId)* and wait for the instance to come up.

*This link is for `us-east-`: if you changed the region in this repo, your dashboard URL needs to reflect that.

To test that your service is working, use the URL output above:

```sh
curl http://container-1-elb-11111.us-east-1.elb.amazonaws.com/health # ok
curl http://container-1-elb-11111.us-east-1.elb.amazonaws.com/endpoint-1 # endpoint-1
```

## Teardown Infrastructure in AWS

Once you're done with this demo (especially if you're using a free AWS account), you'll want to remove all the infrastructure from AWS. Use `terraform destroy` from the `terraform-config` directory, and type `yes` when prompted.

```sh
cd terraform-config
terraform destroy
```

## Connect to the Instance Using SSH

In order to connect to a running instance using SSH, you'll need to set it up with a public key. This repo is set up to easily allow adding a public key pair. The configuration you need is in `keys.tf`, commented out by default.

If you look at `terraform-config/main.tf`, one of the values passed to "ecs_cluster" is `key_pair_name`. This value is defined in `terraform-config/vars.tf`, and currently defaults to the empty string. Once passed into "ecs_cluster", we can see in `terraform-modules/ecs-cluster/main.tf` where it is used, in the "aws_launch_configuration".

```
resource "aws_launch_configuration" "ecs_instance" {
  name_prefix          = "${var.name}-"
  instance_type        = "${var.instance_type}"
  key_name             = "${var.key_pair_name}"
  iam_instance_profile = "${aws_iam_instance_profile.ecs_instance.name}"
  security_groups      = ["${aws_security_group.ecs_instance.id}"]
  image_id             = "${data.aws_ami.ecs.id}"
  // ...
```

*Note*: SSH _will not work_ on an ECS instance without a key pair.

### Generate a New Public Key

You can use an existing ssh key pair or generate a new one specifically for AWS (recommended).

```
$ ssh keygen -t rsa -b 4096 -C "<moore.brittanyann@gmail.com>"
Generating public/private rsa key pair.
Enter file in which to save the key (/Users/brittany/.ssh/id_rsa): /Users/brittany/.ssh/id_rsa.aws
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /Users/brittany/.ssh/id_rsa.aws.
Your public key has been saved in /Users/brittany/.ssh/id_rsa.aws.pub.
```

Next, use `cat` to print your _public_ key (you'll need this in a minute).

```
cat /Users/brittany/.ssh/id_rsa.aws.pub
```

### Update Terraform Configuration

1. In `terraform-config/keys.tf`, uncomment the `aws_key_pair` resource.
2. In `terraform-config/keys.tf`, paste your _public key_ into the `public_key` property.
3. In `terraform-config/vars.tf`, update the `key_pair_name`'s default value to match the name of the key pair in `keys.tf`. This will be `deployer-key` if you haven't modified it.

```
variable "key_pair_name" {
  description = "The name of the Key Pair that can be used to SSH to each EC2 instance in the ECS cluster. Leave blank to not include a Key Pair."
  default     = "deployer-key"
}
```

You'll need to run `terraform apply` again in order to upload your key. Once that's done, you should be able to see your key pair from the EC2 Dashboard (look for "Network & Security" -> "Key Pairs" in the left navigation menu). Your instance should also have a property "Key pair name" that matches the name of your key.

### SSH Into Instance

To ssh into the container, you'll need the "Public DNS" or "Public IP" for your instance.

```
ssh -i <PATH_TO_PUBLIC_KEY> ec2-user@<PUBLIC_DNS>
```

From here, you can run commands like `docker images` to verify your container instance.