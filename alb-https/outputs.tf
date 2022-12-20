# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------
output "arn" {
  value = module.alb.arn
}

output "hostname" {
  value = module.alb.dns_name
}

output "security_group_id" {
  value = module.alb.security_group_id
}

output "listener_id" {
  value = aws_lb_listener.main.id
}
