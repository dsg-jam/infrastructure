variable "name" {
  type        = string
  description = ""
}

variable "location" {
  type        = string
  description = "Cloud Run location. See: <https://cloud.google.com/run/docs/locations>"
}

variable "domain" {
  type        = string
  description = "Verified domain name to use for the service. The service account must be a co-owner of the domain."
}

variable "server_container_image_name" {
  default     = "server"
  type        = string
  description = ""
}
