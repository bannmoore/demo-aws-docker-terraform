output "container_1_url" {
  value = "http://${module.container_1_elb.elb_dns_name}"
}
