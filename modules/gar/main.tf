terraform {
  required_providers {
    google = { source = "hashicorp/google", version = ">= 5.0, < 6.0" }
  }
}

# ---------------------------------------------------------------------------
# APIs
# ---------------------------------------------------------------------------
resource "google_project_service" "artifact_registry" {
  project                    = var.project_id
  service                    = "artifactregistry.googleapis.com"
  disable_on_destroy         = false
  disable_dependent_services = false
}

resource "google_project_service" "container_analysis" {
  project                    = var.project_id
  service                    = "containeranalysis.googleapis.com"
  disable_on_destroy         = false
  disable_dependent_services = false
}

# ---------------------------------------------------------------------------
# Artifact Registry repository
# ---------------------------------------------------------------------------
resource "google_artifact_registry_repository" "images" {
  project       = var.project_id
  location      = var.location
  repository_id = var.repository_id
  description   = var.description
  format        = "DOCKER"

  # Enable vulnerability scanning automatically on push
  docker_config {
    immutable_tags = false
  }

  depends_on = [google_project_service.artifact_registry]
}

# ---------------------------------------------------------------------------
# IAM – additional pull access (e.g. GKE node SAs)
# ---------------------------------------------------------------------------
resource "google_artifact_registry_repository_iam_member" "readers" {
  for_each = toset(var.reader_service_accounts)

  project    = var.project_id
  location   = var.location
  repository = google_artifact_registry_repository.images.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${each.value}"
}
