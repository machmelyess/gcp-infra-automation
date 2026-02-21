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
resource "google_compute_global_forwarding_rule" "default" {
  name       = "http-content-rule"
  target     = google_compute_target_http_proxy.default.id
  port_range = "80"
}

# --- OUTPUT (Pour voir l'IP sur GitHub) ---
output "load_balancer_ip" {
  value = google_compute_global_forwarding_rule.default.ip_address
}