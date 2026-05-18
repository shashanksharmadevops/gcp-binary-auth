variable "project_id" {
  description = "GCP project hosting the Artifact Registry."
  type        = string
}

variable "location" {
  description = "Region for the repository."
  type        = string
}

variable "repository_id" {
  description = "Repository ID."
  type        = string
}

variable "description" {
  description = "Human-readable description."
  type        = string
  default     = ""
}

variable "reader_service_accounts" {
  description = "Service account emails granted artifactregistry.reader."
  type        = list(string)
  default     = []
}
