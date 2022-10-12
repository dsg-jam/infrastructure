terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.40.0"
    }
  }

  backend "gcs" {}
}

provider "google" {
  project = var.project_name
  region  = var.region
}

module "ld51" {
  source   = "./modules/ld51"
  name     = "ld51-server"
  location = var.cloud_run_location
  domain   = "51.${var.domain}"
}
