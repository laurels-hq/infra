# Main Laurels deployment file

data "aws_availability_zones" "available" {
  state = "available"
}

# Setup VPC for all resources
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.stage[terraform.workspace]}-${var.name}-vpc"
  cidr = var.vpc_cidr[terraform.workspace]

  # Pick first 2 AZs
  azs = [
    data.aws_availability_zones.available.names[0],
  data.aws_availability_zones.available.names[1]]
  private_subnets = [
    cidrsubnet(var.vpc_cidr[terraform.workspace], var.vpc_subnet_netbits, 0),
  cidrsubnet(var.vpc_cidr[terraform.workspace], var.vpc_subnet_netbits, 1)]
  public_subnets = [
    cidrsubnet(var.vpc_cidr[terraform.workspace], var.vpc_subnet_netbits, 2),
  cidrsubnet(var.vpc_cidr[terraform.workspace], var.vpc_subnet_netbits, 3)]

  # Setup IPv6
  private_subnet_assign_ipv6_address_on_creation = true
  private_subnet_ipv6_prefixes                   = [1, 2] # must match # of subnets
  public_subnet_assign_ipv6_address_on_creation  = true
  public_subnet_ipv6_prefixes                    = [3, 4] # must match # of subnets
  assign_ipv6_address_on_creation                = true
  enable_ipv6                                    = true

  # Setup single NAT gateway per AZ
  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  single_nat_gateway     = false
  enable_vpn_gateway     = false

  tags = {
    Terraform   = "true"
    Environment = var.stage[terraform.workspace]
  }
}

# Setup Neptune DB
module "neptune" {
  source = "./neptune/"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  stage              = var.stage[terraform.workspace]
  name               = var.name
}

# Setup load balancer
module "lb-www" {
  source = "./alb-https"

  stage           = var.stage[terraform.workspace]
  name            = var.name
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnets
  certificate_arn = var.certificate_arn
}

# Setup ECR repo for docker containers
module "ecr-www" {
  source = "./ecr/"

  namespace = "www"
  stage     = var.stage[terraform.workspace]
  name      = var.name
}

# Setup S3 bucket for app usage
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.4.0"

  bucket = "REDACTED" # Redacted for the sake of this example.
  acl    = "private"

  attach_deny_insecure_transport_policy = true
  block_public_acls                     = true
  block_public_policy                   = true
  ignore_public_acls                    = true
  restrict_public_buckets               = true

  versioning = {
    enabled = true
  }
}

# Setup cluster for Fargate
resource "aws_ecs_cluster" "cluster" {
  name = "${var.stage[terraform.workspace]}-${var.name}-app"
}

# Specific resources for www app
# JWT token
resource "random_password" "jwt" {
  length  = 40
  special = true
}

resource "aws_ssm_parameter" "jwt" {
  name        = "${var.stage[terraform.workspace]}-${var.name}-jwt"
  description = "Secure JWT parameter"
  type        = "SecureString"
  value       = random_password.jwt.result
}

# Get ssm param for image ID
data "aws_ssm_parameter" "deploy_image" {
  name = module.ecr-www.ssm_param
}

# Setup deployment from ECR
module "ecs-fargate-www" {
  source  = "telia-oss/ecs-fargate/aws"
  version = "5.2.0"

  cluster_id                      = aws_ecs_cluster.cluster.id
  name_prefix                     = "${var.stage[terraform.workspace]}-${var.name}-www"
  vpc_id                          = module.vpc.vpc_id
  lb_arn                          = module.lb-www.arn
  private_subnet_ids              = module.vpc.private_subnets
  task_container_assign_public_ip = false
  task_container_port             = var.docker_listen_port
  health_check                    = {}
  task_container_image            = data.aws_ssm_parameter.deploy_image.value
  task_definition_cpu             = 1024
  task_definition_memory          = 2048
  task_container_secrets = [
    {
      name      = "JWT_SECRET"
      valueFrom = aws_ssm_parameter.jwt.arn
    }
  ]
  task_container_environment = {
    NEPTUNE_ENDPOINT     = "wss://${module.neptune.endpoint}"
    BASE_URL             = var.base_url[terraform.workspace]
    S3_BUCKET            = module.s3_bucket.s3_bucket_id
    BACKOFFICE_EMAIL     = var.backoffice_email[terraform.workspace]
    DEFAULT_SENDER_EMAIL = var.default_sender_email[terraform.workspace]
    MIXPANEL_TOKEN       = var.mixpanel_token[terraform.workspace]
    INTERCOM_SECRET      = var.intercom_secret
  }
}

# Final updates once we have the resource IDs
# Ensure LB security group can get to Fargate
resource "aws_security_group_rule" "ingress_www_lb" {
  security_group_id        = module.ecs-fargate-www.service_sg_id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.docker_listen_port
  to_port                  = var.docker_listen_port
  source_security_group_id = module.lb-www.security_group_id
}

# Ensure Neptune security group allows access from Fargate
resource "aws_security_group_rule" "ingress_neptune_sg" {
  security_group_id        = module.neptune.security_group_id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8182
  to_port                  = 8182
  source_security_group_id = module.ecs-fargate-www.service_sg_id
}

# Enable SSM access
data "aws_iam_policy_document" "ecs-params" {
  statement {
    effect = "Allow"

    resources = concat(
      [aws_ssm_parameter.jwt.arn]
    )
    actions = [
      "ssm:GetParameters"
    ]
  }
}

resource "aws_iam_role_policy" "write_params_exc" {
  name   = "access-secure-ssm-params"
  role   = module.ecs-fargate-www.task_execution_role_name
  policy = data.aws_iam_policy_document.ecs-params.json
}

# SES params
resource "aws_iam_role_policy_attachment" "ecs-fargate-www-ses" {
  role       = module.ecs-fargate-www.task_role_name
  policy_arn = "REDACTED" # Redacted for the sake of this example.
}

# Redirect from www to apex
resource "aws_lb_listener_rule" "to-www" {
  listener_arn = module.lb-www.listener_id
  priority     = 1

  action {
    type = "redirect"

    redirect {
      host        = "getlaurels.com"
      status_code = "HTTP_301"
    }
  }

  condition {
    host_header {
      values = ["www.getlaurels.com"]
    }
  }
}

# Point to the correct target group
resource "aws_lb_listener_rule" "to-target-group" {
  listener_arn = module.lb-www.listener_id
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = module.ecs-fargate-www.target_group_arn
  }

  condition {
    path_pattern {
      values = ["/*", "/"]
    }
  }
}
