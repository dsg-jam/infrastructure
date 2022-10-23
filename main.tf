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

resource "google_project_service" "this" {
  for_each = toset([
    "artifactregistry.googleapis.com",  # Artifact Registry
    "compute.googleapis.com",           # Compute Engine,
    "run.googleapis.com",               # Cloud Run
    "storage-component.googleapis.com", # Cloud Storage
  ])

  service                    = each.value
  disable_dependent_services = true
}


# Docker artifact registry
resource "google_artifact_registry_repository" "docker_shared" {
  repository_id = "shared"
  format        = "DOCKER"
  location      = var.region
}

module "gcr_cleaner" {
  source  = "mirakl/gcr-cleaner/google"
  version = "~> 2.0"

  app_engine_application_location     = var.region
  cloud_run_service_location          = var.region
  cloud_run_service_maximum_instances = 5
  cloud_run_service_name              = "gcr-cleaner"
  gar_repositories = [
    {
      region        = google_artifact_registry_repository.docker_shared.location,
      name          = google_artifact_registry_repository.docker_shared.name,
      registry_name = google_artifact_registry_repository.docker_shared.repository_id,
      parameters = {
        grace          = "2h",
        keep           = 3,
        tag_filter_all = ".*"
        recursive      = true,
        dry_run        = false,
      }
    }
  ]
}

# ld51

resource "google_service_account" "ld51_server" {
  account_id   = "ld51-server-deployment"
  display_name = "LD51 Server Deployment"
  project      = var.project_id
}

resource "google_service_account" "ld51_server_run" {
  account_id   = "ld51-server-run"
  display_name = "LD51 Server Run"
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

data "google_compute_default_service_account" "this" {
}

resource "google_service_account_iam_member" "ld51_server_use_sa" {
  for_each = {
    default = data.google_compute_default_service_account.this.id,
    run     = google_service_account.ld51_server_run.id,
  }

  service_account_id = each.value
  member             = local.ld51_server_sa_member
  role               = "roles/iam.serviceAccountUser"
}

resource "google_artifact_registry_repository_iam_member" "ld51_server" {
  repository = google_artifact_registry_repository.docker_shared.name
  location   = google_artifact_registry_repository.docker_shared.location
  member     = local.ld51_server_sa_member
  role       = "roles/artifactregistry.writer"
}
