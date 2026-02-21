# 1. LA VM APACHE
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
      # Pour avoir une IP publique
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# 2. LA VM NGINX
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
    # Pas d'access_config ici si elle est en privé
  }

  
# Dans le bloc metadata de vm_apache ET vm_nginx
metadata = {
  ssh-keys = "ubuntu:${var.ssh_pub_key}"
}