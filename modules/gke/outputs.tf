output "cluster_name" {
  value = google_container_cluster.cluster.name
}

output "cluster_zone" {
  value = google_container_cluster.cluster.location
}

output "cluster_endpoint" {
  value     = google_container_cluster.cluster.endpoint
  sensitive = true
}

output "get_credentials_cmd" {
  value = "gcloud container clusters get-credentials ${var.name} --zone ${var.zone} --project ${var.project_id}"
}
