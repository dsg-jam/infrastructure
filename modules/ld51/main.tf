resource "google_artifact_registry_repository" "default" {
  repository_id = var.name
  format        = "DOCKER"
  location      = var.location
}

locals {
  server_container_image = format(
    "%s-docker.pkg.dev/%s/%s/%s",
    google_artifact_registry_repository.default.location,
    google_artifact_registry_repository.default.project,
    google_artifact_registry_repository.default.repository_id,
    var.server_container_image_name,
  )
}

resource "google_cloud_run_service" "default" {
  name     = var.name
  location = var.location

  traffic {
    percent         = 100
    latest_revision = true
  }

  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "1"
      }
    }

    spec {
      containers {
        image = local.server_container_image
        ports {
          container_port = 80
        }
      }

      timeout_seconds = 3600
    }
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  service  = google_cloud_run_service.default.name
  location = google_cloud_run_service.default.location
  project  = google_cloud_run_service.default.project

  policy_data = data.google_iam_policy.noauth.policy_data
}

resource "google_cloud_run_domain_mapping" "default" {
  name     = var.domain
  location = var.location

  spec {
    route_name       = google_cloud_run_service.default.name
    certificate_mode = "AUTOMATIC"
  }

  metadata {
    namespace = google_cloud_run_service.default.project
  }
}
