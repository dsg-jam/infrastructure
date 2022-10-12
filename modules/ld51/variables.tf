variable "name" {
  description = ""
  type        = string
}

variable "location" {
  description = "Cloud Run location. See: <https://cloud.google.com/run/docs/locations>"
  type        = string
}

variable "domain" {
  description = "Verified domain name to use for the service. The service account must be a co-owner of the domain."
  type        = string
}
