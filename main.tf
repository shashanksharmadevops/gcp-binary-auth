# ---------------------------------------------------------------------------
# 1. Shared GAR (same across all workspaces; idempotent)
# ---------------------------------------------------------------------------
module "gar" {
  source = "./modules/gar"

  project_id    = var.gar_project_id
  location      = var.gar_location
  repository_id = var.gar_repository_id
  description   = var.gar_description

  # GKE node service accounts that need to pull images
  reader_service_accounts = var.extra_gar_readers
}

# ---------------------------------------------------------------------------
# 2. Attestation project – APIs + IAM (one per env)
# ---------------------------------------------------------------------------
module "attestation" {
  source = "./modules/attestation"

  attestation_project_id = var.attestation_project_id
  attestor_project_id    = var.attestor_project_id
  gke_project_id         = var.gke_project_id
}

# ---------------------------------------------------------------------------
# 3. Attestors (one module call per attestor via for_each)
# Each creates: KMS keyring+key, CA note, attestor, IAM bindings
# ---------------------------------------------------------------------------
module "attestor" {
  source   = "./modules/attestor"
  for_each = var.attestors

  attestor_project_id    = var.attestor_project_id
  attestation_project_id = var.attestation_project_id
  gke_project_id         = var.gke_project_id

  attestor_name    = local.attestor_names[each.key]
  note_id          = local.note_ids[each.key]
  display_name     = each.value.display_name

  kms_keyring_name     = each.value.kms_keyring_name
  kms_key_name         = each.value.kms_key_name
  kms_location         = each.value.kms_location
  kms_key_algorithm    = each.value.kms_key_algorithm
  kms_protection_level = each.value.kms_protection_level

  depends_on = [module.attestation]
}

# ---------------------------------------------------------------------------
# 4. GKE clusters (one module call per cluster via for_each)
# Each creates: cluster, node pool, BinAuthz policy referencing all attestors
# ---------------------------------------------------------------------------
module "gke" {
  source   = "./modules/gke"
  for_each = var.clusters

  project_id  = var.gke_project_id
  name        = each.value.name
  zone        = each.value.zone
  node_count  = each.value.node_count
  machine_type = each.value.machine_type

  enforcement_mode              = each.value.enforcement_mode
  global_policy_evaluation_mode = each.value.global_policy_evaluation_mode

  # Policy requires attestation from ALL attestors in this env
  attestor_resource_names = local.attestor_resource_names

  depends_on = [module.attestor]
}
