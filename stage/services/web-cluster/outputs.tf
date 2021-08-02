output "alb_dns_name" {
  description = "The FQDN of the load balancer"
  value = module.web_cluster.alb_dns_name
}