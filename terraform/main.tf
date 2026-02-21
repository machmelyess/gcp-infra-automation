# --- HEALTH CHECK (La pièce manquante) ---
resource "google_compute_http_health_check" "default" {
  name               = "http-health-check"
  request_path       = "/"
  check_interval_sec = 5
  timeout_sec        = 5
}

# --- GROUPS ---
resource "google_compute_instance_group" "apache_group" {
  name      = "apache-group"
  zone      = var.zone
  instances = [google_compute_instance.vm_apache.self_link]
  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_instance_group" "nginx_group" {
  name      = "nginx-group"
  zone      = var.zone
  instances = [google_compute_instance.vm_nginx.self_link]
  named_port {
    name = "http"
    port = 80
  }
}

# --- BACKEND SERVICE ---
resource "google_compute_backend_service" "default" {
  name          = "backend-service"
  # Utilise ici la ressource déclarée plus haut
  health_checks = [google_compute_http_health_check.default.id]
  
  backend {
    group = google_compute_instance_group.apache_group.id
  }

  backend {
    group = google_compute_instance_group.nginx_group.id
  }
}

# --- FIREWALL ---
resource "google_compute_firewall" "allow_health_check" {
  name          = "allow-health-check"
  network       = google_compute_network.vpc_network.name
  direction     = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["http-server"] 
}

# --- URL MAP & PROXY ---
resource "google_compute_url_map" "default" {
  name            = "web-map"
  default_service = google_compute_backend_service.default.id
}

resource "google_compute_target_http_proxy" "default" {
  name    = "http-proxy"
  url_map = google_compute_url_map.default.id
}

# --- FORWARDING RULE ---
# --- 1. Firewall pour les Health Checks (Port 80) ---
resource "google_compute_firewall" "allow_health_check" {
  name          = "allow-health-check"
  network       = google_compute_network.vpc_network.name
  direction     = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["http-server"]
} # <--- VÉRIFIE BIEN CETTE ACCOLADE !

# --- 2. Firewall pour le SSH via IAP (Port 22) ---
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-ssh-via-iap"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["allow-ssh"]
}
# On change le nom interne en "default"
resource "google_compute_global_forwarding_rule" "default" {
  name       = "http-content-rule" # Ça, c'est le nom affiché dans la console Google
  target     = google_compute_target_http_proxy.default.id
  port_range = "80"
}
# 1. Créer le Cloud Router
resource "google_compute_router" "router" {
  name    = "nat-router"
  network = google_compute_network.vpc_network.name
  region  = var.region
}

# 2. Créer le Cloud NAT
resource "google_compute_router_nat" "nat" {
  name                               = "nat-config"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}