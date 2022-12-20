# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "name" {
  description = "The name of the service being deployed."
  type        = string
  default     = "laurels"
}
variable "stage" {
  description = "The stage for the resources (dev, stage, prod, etc)."
  type        = string
  default     = "prod"
}
variable "certificate_arn" {
  description = "The ACM certificate ARN."
  type        = string
}
variable "vpc_id" {
  description = "The VPC ID."
  type        = string
}
variable "subnet_ids" {
  description = "A list of subnets inside the VPC"
  type        = list(string)
}
