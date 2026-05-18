terraform {
  required_providers {
    google      = { source = "hashicorp/google",      version = ">= 5.0, < 6.0" }
    google-beta = { source = "hashicorp/google-beta", version = ">= 5.0, < 6.0" }
  }
}

# ---------------------------------------------------------------------------
# APIs
# ---------------------------------------------------------------------------
resource "google_project_service" "container" {
  project                    = var.project_id
  service                    = "container.googleapis.com"
  disable_on_destroy         = false
  disable_dependent_services = false
}

resource "google_project_service" "binauthz" {
  project                    = var.project_id
  service                    = "binaryauthorization.googleapis.com"
  disable_on_destroy         = false
  disable_dependent_services = false
}

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
# GKE cluster
# ---------------------------------------------------------------------------
resource "google_container_cluster" "cluster" {
  provider = google-beta
  project  = var.project_id
  name     = var.name
  location = var.zone

  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  remove_default_node_pool = true
  initial_node_count       = 1

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {}

  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  depends_on = [
    google_project_service.container,
    google_project_service.binauthz,
  ]
}

resource "google_container_node_pool" "nodes" {
  project    = var.project_id
  name       = "${var.name}-nodes"
  cluster    = google_container_cluster.cluster.name
  location   = var.zone
  node_count = var.node_count

  node_config {
    machine_type = var.machine_type
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# ---------------------------------------------------------------------------
# Binary Authorization policy
# Requires attestation from ALL attestors passed in (AND semantics).
# ---------------------------------------------------------------------------
resource "google_binary_authorization_policy" "policy" {
  project = var.project_id

  global_policy_evaluation_mode = var.global_policy_evaluation_mode

  default_admission_rule {
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = var.enforcement_mode

    require_attestations_by = var.attestor_resource_names
  }

  depends_on = [
    google_project_service.binauthz,
    google_container_cluster.cluster,
  ]
}
