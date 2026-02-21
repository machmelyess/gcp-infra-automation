terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = " 5.0" # Utilise la version 5 pour les dernières fonctionnalités
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  # PAS DE LIGNE "credentials = ..." ICI !
}