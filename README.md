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
