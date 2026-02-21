# VPC
resource "google_compute_network" "vpc_network" {
  name                    = "my-vpc"
  auto_create_subnetworks = false
}

# Subnet Public (pour VM1 Apache)
resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

# Subnet Privé (pour VM2 Nginx)
resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

# Firewall : Autoriser HTTP (80) et SSH (22)
resource "google_compute_firewall" "allow_http_ssh" {
  name    = "allow-http-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["20", "80", "22"]
  }

  source_ranges = ["0.0.0.0/0"]
}