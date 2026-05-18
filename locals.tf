# ---------------------------------------------------------------------------
# Workspace / env guard
# Prevents applying the wrong workspace to the wrong env.
# ---------------------------------------------------------------------------
locals {
  # Fail fast if the user runs `terraform apply` in the wrong workspace.
  workspace_check = terraform.workspace == var.env ? true : tobool(
    "ERROR: Terraform workspace '${terraform.workspace}' does not match var.env '${var.env}'. ",
    "Run: terraform workspace select ${var.env}"
  )

  # Short prefix for resource names; keeps names under GCP limits.
  prefix = var.env

  # Resolved attestor names (env-prefixed for uniqueness across projects)
  attestor_names = {
    for key, att in var.attestors :
    key => "${local.prefix}-${key}-attestor"
  }

  # Resolved note IDs
  note_ids = {
    for key, att in var.attestors :
    key => "${local.prefix}-${key}-note"
  }

  # All GKE cluster names resolved
  cluster_names = {
    for key, cluster in var.clusters :
    key => cluster.name
  }

  # The BinAuthz policy for every cluster references all attestors in this env.
  # A GKE deployment must be signed by ALL attestors (AND logic).
  attestor_resource_names = [
    for key in keys(var.attestors) :
    "projects/${var.attestor_project_id}/attestors/${local.attestor_names[key]}"
  ]
}
