# 1. LA VM APACHE (Subnet Public)
resource "google_compute_instance" "vm_apache" {
  name         = "vm-apache"
  machine_type = "f1-micro"
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.id
    access_config {
      # Donne une IP publique pour Ansible et le Web
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_pub_key}"
  }
} # <-- Vérifie que cette accolade est là

# 2. LA VM NGINX (Subnet Privé)
resource "google_compute_instance" "vm_nginx" {
  name         = "vm-nginx"
  machine_type = "f1-micro"
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.id
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_pub_key}"
  }
} # <-- C'est celle-ci qui manquait probablement !