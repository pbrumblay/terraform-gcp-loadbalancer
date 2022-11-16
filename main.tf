
resource "google_compute_url_map" "https_redirect" {
  project = var.project_id
  name = "${var.resource_prefix}${var.cloudrun_service_name}-https-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "https_redirect" {
  project = var.project_id
  name   = "${var.resource_prefix}${var.cloudrun_service_name}-http-proxy"
  url_map = google_compute_url_map.https_redirect.id
}

// ipv4
resource "google_compute_global_forwarding_rule" "https_redirect_ipv4" {
  project = var.project_id
  name   = "${var.resource_prefix}${var.cloudrun_service_name}-http-lb"

  target = google_compute_target_http_proxy.https_redirect.id
  port_range = "80"
  ip_address = google_compute_global_address.lb_ipv4.address
}

resource "google_compute_global_forwarding_rule" "https_forward_ipv4" {
  project = var.project_id
  name   = "${var.resource_prefix}${var.cloudrun_service_name}-https-lb"

  target = google_compute_target_https_proxy.https_proxy.id
  port_range = "443"
  ip_address = google_compute_global_address.lb_ipv4.address
}

// ipv6
resource "google_compute_global_forwarding_rule" "https_redirect_ipv6" {
  project = var.project_id
  name   = "${var.resource_prefix}${var.cloudrun_service_name}-http-ipv6-lb"

  target = google_compute_target_http_proxy.https_redirect.id
  port_range = "80"
  ip_address = google_compute_global_address.lb_ipv6.address
}

resource "google_compute_global_forwarding_rule" "https_forward_ipv6" {
  project = var.project_id
  name   = "${var.resource_prefix}${var.cloudrun_service_name}-https-ipv6-lb"

  target = google_compute_target_https_proxy.https_proxy.id
  port_range = "443"
  ip_address = google_compute_global_address.lb_ipv6.address
}

resource "google_compute_target_https_proxy" "https_proxy" {
  project = var.project_id
  name   = "${var.resource_prefix}${var.cloudrun_service_name}-https-proxy"

  url_map          = google_compute_url_map.url_map.id
  
  ssl_certificates = var.ssl_certificates
}

resource "google_compute_url_map" "url_map" {
  project = var.project_id
  name = "${var.resource_prefix}${var.cloudrun_service_name}-urlmap"
  
  host_rule {
    hosts        = ["cdn.${var.host_name}"]
    path_matcher = "cdn"
  }

  path_matcher {
    name = "cdn"
    default_service = google_compute_backend_bucket.cdn_backend.id
  }

  default_service = google_compute_backend_service.serverless_backend.id
}

resource "google_compute_backend_service" "serverless_backend" {
  project = var.project_id
  name      = "${var.resource_prefix}${var.cloudrun_service_name}-backend"

  protocol  = "HTTP"
  port_name = "http"
  timeout_sec = 30

  enable_cdn              = true
  cdn_policy {
    cache_mode = "USE_ORIGIN_HEADERS"
    signed_url_cache_max_age_sec = 3600
  }
  security_policy         = google_compute_security_policy.lb_security_policy.id
  custom_request_headers  = null
  custom_response_headers = ["X-Cache-Hit: {cdn_cache_status}"]
  log_config {
    enable = true
    sample_rate = 1.0
  }

  backend {
    group = google_compute_region_network_endpoint_group.serverless_neg.id
  }

  provisioner "local-exec" {
    command = "gcloud compute backend-services update ${var.resource_prefix}${var.cloudrun_service_name}-backend --cache-key-include-named-cookie='store,menu' --global"
  }

  lifecycle {
    ignore_changes = [
      cdn_policy[0].cache_key_policy
    ]
  }
}

resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  provider              = google-beta
  name                  = "${var.resource_prefix}${var.cloudrun_service_name}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = var.cloudrun_service_name
  }
}

resource "google_compute_global_address" "lb_ipv6" {
  project      = var.project_id
  name         = "${var.resource_prefix}${var.cloudrun_service_name}-ipv6"
  address_type = "EXTERNAL"
  ip_version   = "IPV6"
}

resource "google_compute_global_address" "lb_ipv4" {
  project      = var.project_id
  name         = "${var.resource_prefix}${var.cloudrun_service_name}-ipv4"
  address_type = "EXTERNAL"
}

# CDN bucket for next.js static assets
resource "google_compute_backend_bucket" "cdn_backend" {
  project = var.project_id
  name        = "${var.resource_prefix}${var.cloudrun_service_name}-bb"
  description = "Contains next.js static assets"
  bucket_name = google_storage_bucket.cdn_bucket.name
  enable_cdn  = true

  provisioner "local-exec" {
    command = "gcloud compute backend-buckets update ${var.resource_prefix}${var.cloudrun_service_name}-bb --compression-mode=AUTOMATIC"
  }
}

resource "google_storage_bucket" "cdn_bucket" {
  project = var.project_id
  name     = "${var.resource_prefix}${var.cloudrun_service_name}-cdn"
  location = "US"
  uniform_bucket_level_access = true
  cors {
    origin          = var.cors_hosts
    method          = ["GET"]
  }
}

resource "google_storage_bucket_iam_member" "public_rule" {
  bucket = google_storage_bucket.cdn_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}