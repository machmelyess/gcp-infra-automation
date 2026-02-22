# ==========================================================
# 1. INFRASTRUCTURE RÉSEAU (NAT & ROUTER)
# ==========================================================
terraform {
  backend "gcs" {
    bucket  = "terraform-state-test-dev-485716" # Remplace par le nom qui a marché
    prefix  = "terraform/state"
  }
}

# Créer le Cloud Router (Nécessaire pour le NAT)
resource "google_compute_router" "router" {
  name    = "nat-router"
  network = google_compute_network.vpc_network.name
  region  = var.region
}

# Créer le Cloud NAT (Pour que les VMs privées puissent installer des paquets)
resource "google_compute_router_nat" "nat" {
  name                               = "nat-config"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# ==========================================================
# 2. SÉCURITÉ (FIREWALLS)
# ==========================================================

# Règle pour les Health Checks de Google (Port 80)
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

# Règle pour le SSH via IAP (Identity-Aware Proxy)
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

# ==========================================================
# 3. ÉQUILIBRAGE DE CHARGE (LOAD BALANCER)
# ==========================================================

# Health Check HTTP
resource "google_compute_http_health_check" "default" {
  name               = "http-health-check"
  request_path       = "/"
  check_interval_sec = 5
  timeout_sec        = 5
}

# Groupes d'instances
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

# Backend Service
resource "google_compute_backend_service" "default" {
  name          = "backend-service"
  health_checks = [google_compute_http_health_check.default.id]
  
  backend {
    group = google_compute_instance_group.apache_group.id
  }
  backend {
    group = google_compute_instance_group.nginx_group.id
  }
}

# URL Map (Le cerveau du routage)
resource "google_compute_url_map" "default" {
  name            = "web-map"
  default_service = google_compute_backend_service.default.id
}

# Proxy HTTP
resource "google_compute_target_http_proxy" "default" {
  name    = "http-proxy"
  url_map = google_compute_url_map.default.id
}

# Règle de redirection globale (IP Publique du LB)
resource "google_compute_global_forwarding_rule" "default" {
  name       = "http-content-rule"
  target     = google_compute_target_http_proxy.default.id
  port_range = "80"
}


# 4. EXPORTS (OUTPUTS)

output "load_balancer_ip" {
  value = google_compute_global_forwarding_rule.default.ip_address
}