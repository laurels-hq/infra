# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------
output "key_id" {
  value = aws_iam_access_key.ecr-pusher.id
}

output "secret_key" {
  value     = aws_iam_access_key.ecr-pusher.secret
  sensitive = true
}

output "repository_url" {
  value = module.ecr.repository_url
}

output "ssm_param" {
  value = aws_ssm_parameter.ecr_image.name
}
