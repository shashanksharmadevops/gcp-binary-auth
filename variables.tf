# ---------------------------------------------------------------------------
# Environment identity
# ---------------------------------------------------------------------------
variable "env" {
  description = "Environment name. Must match the Terraform workspace (dev | staging | prod)."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "env must be dev, staging, or prod."
  }
}

# ---------------------------------------------------------------------------
# GCP project IDs (user-provided; projects must already exist)
# ---------------------------------------------------------------------------
variable "gar_project_id" {
  description = "Shared project that hosts Artifact Registry. Same value across all workspaces."
  type        = string
}

variable "gke_project_id" {
  description = "Project that hosts GKE clusters and BinAuthz policies for this env."
  type        = string
}

variable "attestor_project_id" {
  description = "Project that hosts attestors, KMS keys, and Container Analysis notes for this env."
  type        = string
}

variable "attestation_project_id" {
  description = "Project that stores attestation occurrences for this env."
  type        = string
}

# ---------------------------------------------------------------------------
# Artifact Registry (shared, workspace-agnostic)
# ---------------------------------------------------------------------------
variable "gar_location" {
  description = "Region for the Artifact Registry repository."
  type        = string
  default     = "us-central1"
}

variable "gar_repository_id" {
  description = "ID of the Artifact Registry Docker repository."
  type        = string
  default     = "container-images"
}

variable "gar_description" {
  description = "Human-readable description of the GAR repository."
  type        = string
  default     = "Shared container image registry"
}

# ---------------------------------------------------------------------------
# GKE clusters (one object per cluster in this env)
# ---------------------------------------------------------------------------
variable "clusters" {
  description = <<-EOT
    Map of GKE clusters to create in this environment.
    Key is a short cluster identifier used in resource names (e.g. "primary", "batch").
  EOT
  type = map(object({
    name                          = string
    zone                          = string
    node_count                    = optional(number, 3)
    machine_type                  = optional(string, "e2-medium")
    enforcement_mode              = optional(string, "ENFORCED_BLOCK_AND_AUDIT_LOG")
    global_policy_evaluation_mode = optional(string, "ENABLE")
  }))

  validation {
    condition = alltrue([
      for k, v in var.clusters :
      contains(["ENFORCED_BLOCK_AND_AUDIT_LOG", "DRYRUN_AUDIT_LOG_ONLY"], v.enforcement_mode)
    ])
    error_message = "enforcement_mode must be ENFORCED_BLOCK_AND_AUDIT_LOG or DRYRUN_AUDIT_LOG_ONLY."
  }

  validation {
    condition = alltrue([
      for k, v in var.clusters :
      contains(["ENABLE", "DISABLE"], v.global_policy_evaluation_mode)
    ])
    error_message = "global_policy_evaluation_mode must be ENABLE or DISABLE."
  }
}

# ---------------------------------------------------------------------------
# Attestors (one object per attestor in this env)
# Each gets its own KMS key in the same attestor project.
# ---------------------------------------------------------------------------
variable "attestors" {
  description = <<-EOT
    Map of attestors to create in this environment.
    Key is a short identifier (e.g. "build", "security-scan", "qa").
    Each attestor gets its own KMS key in the attestor project.
  EOT
  type = map(object({
    display_name         = string
    kms_key_name         = string
    kms_keyring_name     = optional(string, "binauthz-keyring")
    kms_location         = optional(string, "global")
    kms_key_algorithm    = optional(string, "EC_SIGN_P256_SHA256")
    kms_protection_level = optional(string, "SOFTWARE")
  }))

  validation {
    condition = alltrue([
      for k, v in var.attestors :
      contains(["SOFTWARE", "HSM"], v.kms_protection_level)
    ])
    error_message = "kms_protection_level must be SOFTWARE or HSM."
  }
}

# ---------------------------------------------------------------------------
# GAR reader access for GKE (optional list of additional service accounts)
# ---------------------------------------------------------------------------
variable "extra_gar_readers" {
  description = "Additional service account emails that need GAR read access (e.g. GKE node SA)."
  type        = list(string)
  default     = []
}
