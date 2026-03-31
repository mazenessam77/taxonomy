###############################################################################
# Outputs
###############################################################################

# ── VPC ──
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Private subnet IDs (EKS nodes)"
  value       = module.vpc.private_subnets
}

output "database_subnets" {
  description = "Database subnet IDs (RDS)"
  value       = module.vpc.database_subnets
}

# ── EKS ──
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority" {
  description = "EKS cluster CA certificate (base64)"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${local.region} --name ${module.eks.cluster_name}"
}

# ── ECR ──
output "ecr_repository_url" {
  description = "ECR repository URL for Docker push"
  value       = aws_ecr_repository.app.repository_url
}

# ── RDS ──
output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.rds.db_instance_endpoint
}

output "rds_secret_arn" {
  description = "Secrets Manager ARN containing DB credentials"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "database_url" {
  description = "Full DATABASE_URL for application configuration"
  value       = "postgresql://${var.db_username}:<password>@${module.rds.db_instance_address}:5432/${var.db_name}?schema=public"
  sensitive   = true
}

# ── CloudFront ──
output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.app.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.app.domain_name
}
