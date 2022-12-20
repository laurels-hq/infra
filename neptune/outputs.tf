# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------
output "security_group_id" {
  description = "The security group to access this cluster."
  value       = aws_security_group.neptune.id
}
output "endpoint" {
  description = "The endpoint for this Neptune cluster."
  value       = "${aws_neptune_cluster.cluster.endpoint}:8182"
}
