variable "project_id" {
  type = string
}

variable "cloudrun_service_name" {
  type = string
}

variable "resource_prefix" {
  description = "Prefix used when creating resources to allow for multiple load balancers to point to the same cloud run service."
  type = string
  default = ""
}

variable "region" {
  description = "Location for load balancer and Cloud Run resources"
  default     = "us-central1"
}

variable "ssl_certificates" {
  description = "list of certificate ids to add to the https load balancer"
  type = list(string)
}

variable "host_name" {
  description = "primary host name for site"
  type = string
}

variable "cors_hosts" {
  description = "Allowed cors hosts for cdn bucket"
  type = list(string)
}