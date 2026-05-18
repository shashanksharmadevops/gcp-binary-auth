terraform {
  required_providers {
    google = { source = "hashicorp/google", version = ">= 5.0, < 6.0" }
  }
}

# ---------------------------------------------------------------------------
# Data – project numbers for SA email construction
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
# APIs – attestor project (idempotent; harmless if already enabled)
# ---------------------------------------------------------------------------
resource "google_project_service" "binauthz" {
  project                    = var.attestor_project_id
  service                    = "binaryauthorization.googleapis.com"
  disable_on_destroy         = false
  disable_dependent_services = false
}

resource "google_project_service" "container_analysis" {
  project                    = var.attestor_project_id
  service                    = "containeranalysis.googleapis.com"
  disable_on_destroy         = false
  disable_dependent_services = false
}

resource "google_project_service" "kms" {
  project                    = var.attestor_project_id
  service                    = "cloudkms.googleapis.com"
  disable_on_destroy         = false
  disable_dependent_services = false
}

# ---------------------------------------------------------------------------
# KMS – key ring (shared across all attestors in this project)
# Using a single key ring per project is the recommended pattern;
# keys within it are isolated per attestor.
# ---------------------------------------------------------------------------
resource "google_kms_key_ring" "binauthz" {
  project  = var.attestor_project_id
  name     = var.kms_keyring_name
  location = var.kms_location

  depends_on = [google_project_service.kms]
}

# ---------------------------------------------------------------------------
# KMS – asymmetric signing key (one per attestor)
# ---------------------------------------------------------------------------
resource "google_kms_crypto_key" "signing_key" {
  name     = var.kms_key_name
  key_ring = google_kms_key_ring.binauthz.id
  purpose  = "ASYMMETRIC_SIGN"

  version_template {
    algorithm        = var.kms_key_algorithm
    protection_level = var.kms_protection_level
  }

  lifecycle {
    prevent_destroy = false # Set true in production
  }
}

data "google_kms_crypto_key_version" "signing_key" {
  crypto_key = google_kms_crypto_key.signing_key.id
}

# ---------------------------------------------------------------------------
# Container Analysis note
# ---------------------------------------------------------------------------
resource "google_container_analysis_note" "note" {
  project = var.attestor_project_id
  name    = var.note_id

  attestation_authority {
    hint {
      human_readable_name = var.display_name
    }
  }

  depends_on = [google_project_service.container_analysis]
}

# ---------------------------------------------------------------------------
# Binary Authorization attestor
# ---------------------------------------------------------------------------
resource "google_binary_authorization_attestor" "attestor" {
  project = var.attestor_project_id
  name    = var.attestor_name

  attestation_authority_note {
    note_reference = google_container_analysis_note.note.name

    public_keys {
      id = data.google_kms_crypto_key_version.signing_key.id

      pkix_public_key {
        public_key_pem      = data.google_kms_crypto_key_version.signing_key.public_key[0].pem
        signature_algorithm = data.google_kms_crypto_key_version.signing_key.public_key[0].algorithm
      }
    }
  }

  depends_on = [google_project_service.binauthz]
}

# ---------------------------------------------------------------------------
# IAM – KMS: attestor SA can sign; GKE SA can verify
# ---------------------------------------------------------------------------
resource "google_kms_crypto_key_iam_member" "attestor_can_sign" {
  crypto_key_id = google_kms_crypto_key.signing_key.id
  role          = "roles/cloudkms.signerVerifier"
  member        = "serviceAccount:${local.attestor_sa}"
}

resource "google_kms_crypto_key_iam_member" "gke_can_verify" {
  crypto_key_id = google_kms_crypto_key.signing_key.id
  role          = "roles/cloudkms.verifier"
  member        = "serviceAccount:${local.gke_sa}"
}

# ---------------------------------------------------------------------------
# IAM – attestor resource: GKE SA can verify attestations cross-project
# ---------------------------------------------------------------------------
resource "google_binary_authorization_attestor_iam_member" "gke_verifier" {
  project  = var.attestor_project_id
  attestor = google_binary_authorization_attestor.attestor.name
  role     = "roles/binaryauthorization.attestorsVerifier"
  member   = "serviceAccount:${local.gke_sa}"
}

# ---------------------------------------------------------------------------
# IAM – CA note: both SAs need to read occurrences tied to this note
# ---------------------------------------------------------------------------
resource "google_container_analysis_note_iam_member" "attestor_note_viewer" {
  project = var.attestor_project_id
  note    = google_container_analysis_note.note.name
  role    = "roles/containeranalysis.notes.occurrences.viewer"
  member  = "serviceAccount:${local.attestor_sa}"
}

resource "google_container_analysis_note_iam_member" "gke_note_viewer" {
  project = var.attestor_project_id
  note    = google_container_analysis_note.note.name
  role    = "roles/containeranalysis.notes.occurrences.viewer"
  member  = "serviceAccount:${local.gke_sa}"
}
