variable "attestor_project_id" {
  description = "Project hosting attestors, KMS keys, and CA notes."
  type        = string
}

variable "attestation_project_id" {
  description = "Project storing attestation occurrences."
  type        = string
}

variable "gke_project_id" {
  description = "GKE project whose BinAuthz SA needs cross-project verify access."
  type        = string
}

variable "attestor_name" {
  description = "Name of the attestor resource."
  type        = string
}

variable "note_id" {
  description = "Container Analysis note ID."
  type        = string
}

variable "display_name" {
  description = "Human-readable name for the CA note hint."
  type        = string
}

variable "kms_keyring_name" {
  description = "KMS key ring name (shared across attestors in this project)."
  type        = string
}

variable "kms_key_name" {
  description = "KMS asymmetric signing key name for this attestor."
  type        = string
}

variable "kms_location" {
  description = "Location of the KMS key ring."
  type        = string
}

variable "kms_key_algorithm" {
  description = "Signing algorithm."
  type        = string
}

variable "kms_protection_level" {
  description = "KMS protection level (SOFTWARE | HSM)."
  type        = string
}
