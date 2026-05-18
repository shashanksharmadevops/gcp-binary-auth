# Binary Authorization – Multi-Environment Terraform

## Architecture

| Project per env | Purpose |
|---|---|
| **GKE project** | GKE clusters + BinAuthz enforcement policy |
| **Attestor/KMS project** | All attestors + their KMS keys + CA notes for this env |
| **Attestation project** | Occurrence storage for all attestors in this env |
| **GAR project (shared)** | One Artifact Registry repository, used by all envs |

Each env has its own set of these three projects. GAR is shared.

## Directory structure

```
.
├── versions.tf          # Provider + TF version constraints
├── variables.tf         # All input definitions
├── locals.tf            # Workspace guard, name prefixes, derived values
├── main.tf              # Module wiring
├── outputs.tf
├── modules/
│   ├── gar/             # Artifact Registry (idempotent across workspaces)
│   ├── attestation/     # Attestation project APIs + IAM
│   ├── attestor/        # One KMS key + CA note + attestor + IAM (for_each)
│   └── gke/             # One GKE cluster + BinAuthz policy (for_each)
└── envs/
    ├── dev/terraform.tfvars
    ├── staging/terraform.tfvars
    └── prod/terraform.tfvars
```

## Workflow

```bash
# First-time setup (once)
terraform init

# Select workspace and apply
terraform workspace new dev    # or: terraform workspace select dev
terraform apply -var-file=envs/dev/terraform.tfvars

terraform workspace new staging
terraform apply -var-file=envs/staging/terraform.tfvars

terraform workspace new prod
terraform apply -var-file=envs/prod/terraform.tfvars
```

The workspace guard in `locals.tf` will error if `var.env` doesn't match
`terraform.workspace`, preventing accidental cross-env applies.

## Adding an attestor to an env

Add one entry to `attestors` in the relevant `terraform.tfvars`:

```hcl
attestors = {
  # ...existing entries...
  compliance = {
    display_name     = "Compliance sign-off attestor"
    kms_keyring_name = "binauthz-keyring"
    kms_key_name     = "prod-compliance-signing-key"
    kms_location     = "global"
    kms_key_algorithm    = "EC_SIGN_P256_SHA256"
    kms_protection_level = "HSM"
  }
}
```

`terraform apply` creates the KMS key, CA note, attestor, and all IAM
bindings. The GKE BinAuthz policy automatically picks up the new attestor
(all clusters require ALL attestors — AND logic).

## Adding a GKE cluster

Add one entry to `clusters` in the relevant `terraform.tfvars`:

```hcl
clusters = {
  # ...existing...
  gpu = {
    name         = "prod-gpu"
    zone         = "us-central1-c"
    node_count   = 4
    machine_type = "n1-standard-8"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
  }
}
```

## CI/CD signing flow

```bash
# After image is pushed to GAR and vulnerability scan completes:
gcloud beta container binauthz attestations sign-and-create \
  --project="${ATTESTATION_PROJECT_ID}" \
  --artifact-url="${GAR_URL}/${IMAGE}@${DIGEST}" \
  --attestor="${ATTESTOR_NAME}" \
  --attestor-project="${ATTESTOR_PROJECT_ID}" \
  --keyversion-project="${ATTESTOR_PROJECT_ID}" \
  --keyversion-location="global" \
  --keyversion-keyring="binauthz-keyring" \
  --keyversion-key="${KMS_KEY_NAME}" \
  --keyversion="1"
```

## Production checklist

- [ ] Set `kms_protection_level = "HSM"` for all prod attestors
- [ ] Set `lifecycle { prevent_destroy = true }` on prod KMS keys
- [ ] Keep dev clusters in `DRYRUN_AUDIT_LOG_ONLY` until BinAuthz is validated
- [ ] Store tfstate in GCS backend with env-specific bucket or prefix
