# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------
output "ecr-www-key-id" {
  value = module.ecr-www.key_id
}

output "ecr-www-secret-key" {
  value     = module.ecr-www.secret_key
  sensitive = true
}

output "ecr-www-repo-url" {
  value = module.ecr-www.repository_url
}

output "ecr-ssm-param-name" {
  value = module.ecr-www.ssm_param
}

output "www-alb-hostname" {
  value = module.lb-www.hostname
}
