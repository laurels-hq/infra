# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "name" {
  description = "The name of the service being deployed."
  type        = string
  default     = "myapp"
}
variable "stage" {
  description = "The stage for the resources (dev, stage, prod, etc)."
  type        = string
  default     = "dev"
}
variable "vpc_id" {
  description = "The VPC ID."
  type        = string
}
variable "private_subnet_ids" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
}
variable "instance_type" {
  description = "The EC2 instance type to create."
  type        = string
  default     = "db.t3.medium"
}
variable "instance_count" {
  description = "The number of Neptune instances in the cluster"
  type        = string
  default     = 1
}
