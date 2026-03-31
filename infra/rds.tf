###############################################################################
# Amazon RDS PostgreSQL — Private Subnets (Data Tier)
###############################################################################

# Security group: only allow traffic from EKS private subnets
resource "aws_security_group" "rds" {
  name        = "${local.name}-rds-sg"
  description = "Allow PostgreSQL access from EKS nodes only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.name}-rds-sg"
  })
}

# Generate a random password for the RDS master user
resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%^&*()-_=+"
}

# Store the password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${local.name}/rds/master-password"
  description             = "RDS master password for ${local.name}"
  recovery_window_in_days = 7
  tags                    = local.tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    host     = module.rds.db_instance_address
    port     = 5432
    dbname   = var.db_name
    url      = "postgresql://${var.db_username}:${random_password.db_password.result}@${module.rds.db_instance_address}:5432/${var.db_name}?schema=public"
  })
}

###############################################################################
# RDS Instance
###############################################################################

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.5"

  identifier = "${local.name}-db"

  # Engine
  engine               = "postgres"
  engine_version       = "15.5"
  family               = "postgres15"
  major_engine_version = "15"
  instance_class       = var.db_instance_class

  # Storage
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result
  port     = 5432

  # Network — isolated database subnets
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = var.db_multi_az

  # Backup & Maintenance
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # Monitoring
  performance_insights_enabled    = true
  monitoring_interval             = 60
  create_monitoring_role          = true
  monitoring_role_name            = "${local.name}-rds-monitoring"
  monitoring_role_use_name_prefix = false

  # Protection
  deletion_protection = true
  skip_final_snapshot = false
  final_snapshot_identifier = "${local.name}-final-snapshot"

  # Parameters
  parameters = [
    {
      name  = "log_connections"
      value = "1"
    },
    {
      name  = "log_disconnections"
      value = "1"
    }
  ]

  tags = local.tags
}
