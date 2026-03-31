###############################################################################
# General
###############################################################################

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "taxonomy"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

###############################################################################
# VPC & Networking
###############################################################################

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

###############################################################################
# EKS
###############################################################################

variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.29"
}

variable "system_node_instance_types" {
  description = "Instance types for the system (On-Demand) managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "system_node_min_size" {
  description = "Minimum number of nodes in system node group"
  type        = number
  default     = 2
}

variable "system_node_max_size" {
  description = "Maximum number of nodes in system node group"
  type        = number
  default     = 4
}

variable "system_node_desired_size" {
  description = "Desired number of nodes in system node group"
  type        = number
  default     = 2
}

###############################################################################
# RDS (PostgreSQL)
###############################################################################

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum storage autoscaling limit in GB"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "taxonomy"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "taxonomy_admin"
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = true
}

###############################################################################
# Domain & DNS
###############################################################################

variable "domain_name" {
  description = "Domain name for the application (e.g. taxonomy.example.com)"
  type        = string
  default     = "taxonomy.example.com"
}
