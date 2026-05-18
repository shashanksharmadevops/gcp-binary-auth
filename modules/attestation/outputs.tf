output "attestor_sa_email" {
  description = "BinAuthz service account email in the attestor project."
  value       = local.attestor_sa
}

output "gke_sa_email" {
  description = "BinAuthz service account email in the GKE project."
  value       = local.gke_sa
}
