# VM 1 : Apache (Public)
resource "google_compute_instance" "vm_apache" {
  name         = "vm-apache"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.id
    access_config {
      # Donne une IP publique pour l'accès externe
    }
  }
}

# VM 2 : Nginx (Privée)
resource "google_compute_instance" "vm_nginx" {
  name         = "vm-nginx"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.id
    # Pas d'access_config ici = IP privée uniquement
  }
}
resource "google_compute_instance" "vm_apache" {
  # ... (ton code existant)
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "google_compute_instance" "vm_nginx" {
  # ... (ton code existant)
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}