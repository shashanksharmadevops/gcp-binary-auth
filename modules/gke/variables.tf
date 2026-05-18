variable "project_id" {
  description = "GKE project ID."
  type        = string
}

variable "name" {
  description = "GKE cluster name."
  type        = string
}

variable "zone" {
  description = "GCP zone for the cluster."
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the node pool."
  type        = number
  default     = 3
}

variable "machine_type" {
  description = "Node machine type."
  type        = string
  default     = "e2-medium"
}

variable "enforcement_mode" {
  description = "BinAuthz enforcement mode."
  type        = string
  default     = "ENFORCED_BLOCK_AND_AUDIT_LOG"
}

variable "global_policy_evaluation_mode" {
  description = "Allow Google-maintained system images (ENABLE | DISABLE)."
  type        = string
  default     = "ENABLE"
}

variable "attestor_resource_names" {
  description = "List of attestor resource names the policy will require (AND logic)."
  type        = list(string)
}
