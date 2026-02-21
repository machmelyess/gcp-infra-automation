variable "project_id" {
  default = "test-dev-485716"
}

variable "region" {
  default = "europe-west1"
}

variable "zone" {
  default = "europe-west1-b"
}

variable "gcp_svc_key" {
  type        = string
  description = "Chemin vers la clé JSON"
  default     = "C:/Users/MACH-ELYES/Desktop/numeryx_doc/demo-gcp/test-dev-485716-3c3e84daa303.json"
}
variable "gcp_zone" {
  description = "La zone GCP pour les instances"
  type        = string
  default     = "europe-west1-b" # Ou une autre zone de ta région
}