terraform {
  required_providers {
    google = { source = "hashicorp/google", version = ">= 5.0, < 6.0" }
  }
}

# ---------------------------------------------------------------------------
# Data – resolve project numbers for SA email construction
# ---------------------------------------------------------------------------
data "google_project" "attestor" {
  project_id = var.attestor_project_id
}

data "google_project" "gke" {
  project_id = var.gke_project_id
}

locals {
  attestor_sa = "service-${data.google_project.attestor.number}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"
  gke_sa      = "service-${data.google_project.gke.number}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"
}

# ---------------------------------------------------------------------------
# APIs – attestation project
# ---------------------------------------------------------------------------
resource "google_project_service" "container_analysis" {
  project                    = var.attestation_project_id
  service                    = "containeranalysis.googleapis.com"
  disable_on_destroy         = false
  disable_dependent_services = false
}

resource "google_project_service" "binauthz" {
  project                    = var.attestation_project_id
  service                    = "binaryauthorization.googleapis.com"
  disable_on_destroy         = false
  disable_dependent_services = false
}

# ---------------------------------------------------------------------------
# IAM – attestation project
#
# Attestor SA needs to write occurrences (sign-and-create in CI/CD)
# GKE SA needs to read occurrences (policy evaluation at deploy time)
# ---------------------------------------------------------------------------
resource "google_project_iam_member" "attestor_occurrences_viewer" {
  project = var.attestation_project_id
  role    = "roles/containeranalysis.occurrences.viewer"
  member  = "serviceAccount:${local.attestor_sa}"

  depends_on = [google_project_service.container_analysis]
}

resource "google_project_iam_member" "gke_occurrences_viewer" {
  project = var.attestation_project_id
  role    = "roles/containeranalysis.occurrences.viewer"
  member  = "serviceAccount:${local.gke_sa}"

  depends_on = [google_project_service.container_analysis]
}

resource "google_project_iam_member" "attestor_notes_attacher" {
  project = var.attestation_project_id
  role    = "roles/containeranalysis.notes.attacher"
  member  = "serviceAccount:${local.attestor_sa}"

  depends_on = [google_project_service.container_analysis]
}
