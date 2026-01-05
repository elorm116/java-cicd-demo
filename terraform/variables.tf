# Define Variables
variable "subnet_cidr" {
  default     = "10.0.1.0/24"
  description = "The CIDR block for the subnet"
}
variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "The CIDR block for the VPC"
}
variable "availability_zone" {
  default     = "us-east-1a"
  description = "The availability zone for the subnet"
}
variable "env_prefix" {
  default     = "dev"
  description = "The environment where resources will be created"
}
variable "instance_type" {
  default     = "t2.micro"
  description = "The EC2 instance type"
}

variable "route_cidr" {
  description = "The destination CIDR block for the route"
  type        = string
  default     = "0.0.0.0/0"
}
