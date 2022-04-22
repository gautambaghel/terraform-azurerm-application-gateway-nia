output "consul_url" {
  value = hcp_consul_cluster.main.consul_public_endpoint_url
}

output "consul_token" {
  value     = hcp_consul_cluster_root_token.token.secret_id
  sensitive = true
}