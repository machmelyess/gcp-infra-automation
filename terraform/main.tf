# Instance Group (pour le LB)
resource "google_compute_instance_group" "web_group" {
  name        = "web-servers-group"
  description = "Groupe pour le Load Balancer"
  instances   = [
    google_compute_instance.vm_apache.self_link,
    google_compute_instance.vm_nginx.self_link
  ]
  named_port {
    name = "http"
    port = 80
  }
  zone = var.zone
}

# Backend Service
resource "google_compute_backend_service" "default" {
  name          = "backend-service"
  health_checks = [google_compute_http_health_check.default.id]
  backend {
    group = google_compute_instance_group.web_group.id
  }
}

# Health Check
resource "google_compute_http_health_check" "default" {
  name               = "http-health-check"
  request_path       = "/"
  check_interval_sec = 5
}

# URL Map & Proxy HTTP
resource "google_compute_url_map" "default" {
  name            = "web-map"
  default_service = google_compute_backend_service.default.id
}

resource "google_compute_target_http_proxy" "default" {
  name    = "http-proxy"
  url_map = google_compute_url_map.default.id
}

# IP Globale du LB
resource "google_compute_global_forwarding_rule" "default" {
  name       = "http-content-rule"
  target     = google_compute_target_http_proxy.default.id
  port_range = "80"
}