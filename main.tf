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

module "google_project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 14.0"

  project_id = var.project_id

  activate_apis = [
    "artifactregistry.googleapis.com",     # Artifact Registry
    "cloudresourcemanager.googleapis.com", # Cloud Resource Manager
    "compute.googleapis.com",              # Compute Engine,
    "iam.googleapis.com",                  # Identity and Access Management
    "run.googleapis.com",                  # Cloud Run
    "storage-component.googleapis.com",    # Cloud Storage
  ]
}

# Docker artifact registry
resource "google_artifact_registry_repository" "docker_shared" {
  repository_id = "shared"
  format        = "DOCKER"
  location      = var.region
}

# ld51

resource "google_service_account" "ld51_server" {
  account_id   = "ld51-server-deployment"
  display_name = "LD51 Server Deployment"
  project      = var.project_id
}

locals {
  ld51_server_sa_member = format("serviceAccount:%s", google_service_account.ld51_server.email)
}

resource "google_project_iam_member" "ld51_server" {
  member  = local.ld51_server_sa_member
  role    = "roles/run.admin"
  project = google_service_account.ld51_server.project
}

resource "google_service_account_iam_member" "ld51_server" {
  service_account_id = google_service_account.ld51_server.name
  member             = local.ld51_server_sa_member
  role               = "roles/iam.serviceAccountTokenCreator"
}

data "google_compute_default_service_account" "default" {
}

resource "google_service_account_iam_member" "ld51_server_use_compute" {
  service_account_id = data.google_compute_default_service_account.default.id
  member             = local.ld51_server_sa_member
  role               = "roles/iam.serviceAccountUser"
}

resource "google_artifact_registry_repository_iam_member" "ld51_server" {
  repository = google_artifact_registry_repository.docker_shared.name
  location   = google_artifact_registry_repository.docker_shared.location
  member     = local.ld51_server_sa_member
  role       = "roles/artifactregistry.writer"
}
