# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "namespace" {
  description = "The namespace for the resources."
  type        = string
  default     = "app"
}
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
