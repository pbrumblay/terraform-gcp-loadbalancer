output ipv4_addr {
  description = "The IPv4 address of the LB"
  value       = "${google_compute_global_address.lb_ipv4.address}"
}

output ipv6_addr {
  description = "The IPv6 address of the LB"
  value       = "${google_compute_global_address.lb_ipv6.address}"
}

output cdn_bucket {
  value = google_storage_bucket.cdn_bucket
}