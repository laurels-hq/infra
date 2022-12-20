# Provision & deploy an AWS Neptune cluster

# Data for this module
data "aws_neptune_engine_version" "default" {
  version = "1.0.5.1"
}

# Security groups
resource "aws_security_group" "neptune" {
  vpc_id      = var.vpc_id
  name        = "${var.stage}-${var.name}-neptune-sg"
  description = "Neptune security group"
}

resource "aws_security_group_rule" "egress_service" {
  security_group_id = aws_security_group.neptune.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "ingress_self" {
  security_group_id = aws_security_group.neptune.id
  type              = "ingress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  self              = true
}

# Neptune resources
resource "aws_neptune_cluster_parameter_group" "default" {
  family      = "neptune1"
  name_prefix = "${var.stage}-${var.name}-params"
  description = "Neptune cluster parameter group"

  parameter {
    name  = "neptune_enable_audit_log"
    value = 1
  }
}

resource "aws_neptune_subnet_group" "default" {
  name_prefix = "${var.stage}-${var.name}-subnet"
  subnet_ids  = var.private_subnet_ids
}

resource "aws_neptune_cluster" "cluster" {
  cluster_identifier_prefix            = "${var.stage}-${var.name}-neptune"
  engine                               = "neptune"
  engine_version                       = data.aws_neptune_engine_version.default.version
  enable_cloudwatch_logs_exports       = ["audit"]
  neptune_cluster_parameter_group_name = aws_neptune_cluster_parameter_group.default.id
  neptune_subnet_group_name            = aws_neptune_subnet_group.default.id
  backup_retention_period              = 14
  port                                 = 8182
  vpc_security_group_ids               = [aws_security_group.neptune.id]
  storage_encrypted                    = true
  skip_final_snapshot                  = true
  iam_database_authentication_enabled  = false
  apply_immediately                    = true
}

resource "aws_neptune_parameter_group" "default" {
  family = "neptune1"
  name   = "${aws_neptune_cluster_parameter_group.default.id}-instance"
}

resource "aws_neptune_cluster_instance" "instances" {
  count                        = var.instance_count
  cluster_identifier           = aws_neptune_cluster.cluster.id
  identifier_prefix            = "${var.stage}-${var.name}-instance"
  engine                       = "neptune"
  instance_class               = var.instance_type
  apply_immediately            = true
  neptune_subnet_group_name    = aws_neptune_subnet_group.default.id
  neptune_parameter_group_name = aws_neptune_parameter_group.default.id
  port                         = 8182
  publicly_accessible          = false
}
