# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "region" {
  description = "The region where to deploy this code."
  default     = "us-east-1"
}

variable "key_pair_name" {
  description = "The name of the Key Pair that can be used to SSH to each EC2 instance in the ECS cluster. Leave blank to not include a Key Pair."
  default     = ""
}

variable "container_1_image" {
  description = "The name of the Docker image to deploy for the container"
  default     = "bann/container-1"
}

variable "container_1_version" {
  description = "The version (i.e. tag) of the Docker container to deploy for the container"
  default     = "local"
}

variable "container_1_port" {
  description = "The port the container Docker container listens on for HTTP requests"
  default     = 3000
}
