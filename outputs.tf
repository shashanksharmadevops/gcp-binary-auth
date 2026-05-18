output "gar_repository_url" {
  description = "Full URL of the Artifact Registry repository."
  value       = module.gar.repository_url
}

output "attestors" {
  description = "Map of attestor key → resource name, KMS key version ID."
  value = {
    for key in keys(var.attestors) : key => {
      resource_name    = module.attestor[key].attestor_resource_name
      kms_key_version  = module.attestor[key].kms_key_version_id
      note_name        = module.attestor[key].note_name
    }
  }
}

output "clusters" {
  description = "Map of cluster key → name, zone, get-credentials command."
  value = {
    for key in keys(var.clusters) : key => {
      name                = module.gke[key].cluster_name
      zone                = module.gke[key].cluster_zone
      get_credentials_cmd = module.gke[key].get_credentials_cmd
    }
  }
}

output "attestation_project_id" {
  description = "Project that stores attestation occurrences for this env."
  value       = var.attestation_project_id
}
