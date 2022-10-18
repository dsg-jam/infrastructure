terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.40"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.41"
    }
  }

  backend "gcs" {}
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "google-project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 14.0"

  project_id = var.project_id

  activate_apis = [
    "artifactregistry.googleapis.com",  # Artifact Registry
    "iam.googleapis.com",               # Identity and Access Management
    "run.googleapis.com",               # Cloud Run
    "storage-component.googleapis.com", # Cloud Storage
  ]
}

# Docker artifact registry
resource "google_artifact_registry_repository" "docker-shared" {
  repository_id = "shared"
  format        = "DOCKER"
  location      = var.region
}

# ld51

resource "google_service_account" "ld51-server" {
  account_id   = "ld51-server-deployment"
  display_name = "LD51 Server Deployment"
  project      = var.project_id
}

locals {
  ld51-server_service-account_member = format("serviceAccount:%s", google_service_account.ld51-server.email)
}

resource "google_project_iam_member" "ld51-server" {
  member  = local.ld51-server_service-account_member
  role    = "roles/run.admin"
  project = google_service_account.ld51-server.project
}


resource "google_artifact_registry_repository_iam_member" "ld51-server" {
  repository = google_artifact_registry_repository.docker-shared.repository_id
  location   = google_artifact_registry_repository.docker-shared.location
  member     = local.ld51-server_service-account_member
  role       = "roles/artifactregistry.writer"
}
