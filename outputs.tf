output "color_url" {
  value = "https://${local.custom_domain_name}"
}
output "aws_region" {
  value = local.aws_region
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "ecr_repo_url" {
  value = module.ecr.repository_url
}

output "elasticache_host" {
  value = aws_elasticache_replication_group.elasticache.configuration_endpoint_address
}

output "elasticache_port" {
  value = aws_elasticache_replication_group.elasticache.port
}

output "elasticache_user" {
  value = aws_elasticache_user.elasticache.user_name
}

output "elasticache_expiration" {
  value = local.elasticache_expiration
}

output "elasticache_password" {
  value = random_password.elasticache.result
  sensitive = true
}

output "elasticache_secret_key" {
  value = random_password.elasticache_secret_key.result
  sensitive = true
}

output "acm_certificate_arn" {
  value = aws_acm_certificate_validation.color.certificate_arn
}

output "color_dns_name" {
  value = local.custom_domain_name
}

output "domain_filter" {
  value = local.public_domain
}

output "k8s_sa_alb_name" {
  value = kubernetes_service_account.alb_service_account.metadata[0].name
}

output "k8s_sa_external_dns_name" {
  value = kubernetes_service_account.external_dns_service_account.metadata[0].name
}
