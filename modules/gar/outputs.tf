output "repository_url" {
  description = "Full URL of the Artifact Registry repository."
  value       = "${var.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.images.name}"
}

output "repository_id" {
  description = "Repository resource ID."
  value       = google_artifact_registry_repository.images.id
}
