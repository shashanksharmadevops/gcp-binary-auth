variable "attestation_project_id" {
  description = "Project that stores attestation occurrences."
  type        = string
}

variable "attestor_project_id" {
  description = "Project hosting attestors — its BinAuthz SA needs write access here."
  type        = string
}

variable "gke_project_id" {
  description = "Project hosting GKE clusters — its BinAuthz SA needs read access here."
  type        = string
}
