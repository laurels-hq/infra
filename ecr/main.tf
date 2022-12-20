# Module to setup an ECR instance with credentials to push images
resource "aws_iam_user" "ecr-pusher" {
  name = "${var.stage}-ecr-image-pusher-${var.namespace}-${var.name}"
}

resource "aws_iam_user_policy_attachment" "ecr-pusher" {
  user       = aws_iam_user.ecr-pusher.name
  policy_arn = "REDACTED" # Redacted for the sake of this example.
}

resource "aws_iam_access_key" "ecr-pusher" {
  user = aws_iam_user.ecr-pusher.name
}

resource "aws_ssm_parameter" "ecr_image" {
  name        = "${var.stage}-${var.name}-deploy"
  description = "Current deployment image ID"
  type        = "String"
  value       = "${module.ecr.repository_url}:latest"
  overwrite   = true

  lifecycle {
    # Ignore value changes - we expect them as part of CI
    ignore_changes = [value]
  }
}

# Manual policy to enable user to update SSM param store
data "aws_iam_policy_document" "ecr_image" {
  statement {
    effect = "Allow"

    resources = concat(
      [aws_ssm_parameter.ecr_image.arn]
    )
    actions = [
      "ssm:GetParameter",
      "ssm:PutParameter",
    ]
  }
}

resource "aws_iam_user_policy" "write_params" {
  name   = "write-image-deployment-param"
  user   = aws_iam_user.ecr-pusher.name
  policy = data.aws_iam_policy_document.ecr_image.json
}

# Docker registry for main app
module "ecr" {
  source                 = "cloudposse/ecr/aws"
  version                = "0.34.0"
  image_tag_mutability   = "MUTABLE"
  namespace              = var.namespace
  stage                  = var.stage
  name                   = var.name
  use_fullname           = true
  principals_full_access = [aws_iam_user.ecr-pusher.arn]
}
