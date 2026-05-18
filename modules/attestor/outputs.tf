output "attestor_resource_name" {
  description = "Full resource name of the attestor."
  value       = "projects/${var.attestor_project_id}/attestors/${google_binary_authorization_attestor.attestor.name}"
}

output "kms_key_version_id" {
  description = "Full resource ID of the KMS key version used for signing."
  value       = data.google_kms_crypto_key_version.signing_key.id
}

output "kms_key_ring_id" {
  description = "Full resource ID of the KMS key ring."
  value       = google_kms_key_ring.binauthz.id
}

output "note_name" {
  description = "Full resource name of the Container Analysis note."
  value       = google_container_analysis_note.note.name
}
