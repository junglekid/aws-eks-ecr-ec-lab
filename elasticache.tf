# Create Amazon ElastiCache Security Group
module "elasticache_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/redis"

  name        = "elasticache"
  description = "Security group for ElastiCache with 6379 ports open within VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [local.vpc_cidr]
}

# Create AWS ElastiCache Cluster
resource "aws_elasticache_replication_group" "elasticache" {
  replication_group_id        = local.elasticache_cluster_id
  description                 = local.project
  node_type                   = "cache.t3.small"
  engine_version              = "7.0"
  port                        = 6379
  parameter_group_name        = "default.redis7.cluster.on"
  automatic_failover_enabled  = true
  multi_az_enabled            = true
  subnet_group_name           = module.vpc.elasticache_subnet_group
  security_group_ids          = [module.elasticache_sg.security_group_id]
  preferred_cache_cluster_azs = local.azs
  num_cache_clusters          = 3
  at_rest_encryption_enabled  = true
  transit_encryption_enabled  = true
  user_group_ids              = [aws_elasticache_user_group.elasticache.id]

  depends_on = [module.vpc]
}

# Generate random password for AWS ElastiCache User
resource "random_password" "elasticache" {
  length           = 32
  special          = true
  override_special = "!&*()-_=+[]{}<>:?"
}

# Generate random password for AWS ElastiCache Secret Key 
resource "random_password" "elasticache_secret_key" {
  length  = 32
  special = false
}

# Create AWS ElastiCache User
resource "aws_elasticache_user" "elasticache" {
  user_id       = local.elasticache_username
  user_name     = local.elasticache_username
  access_string = "on ~* -@all +@connection +@write +@read +info +cluster|slots"
  engine        = "REDIS"
  passwords     = [random_password.elasticache.result]
}

# Create AWS ElastiCache User Group
resource "aws_elasticache_user_group" "elasticache" {
  engine        = "REDIS"
  user_group_id = "${local.elasticache_cluster_id}-group"
  user_ids      = ["default", aws_elasticache_user.elasticache.user_id]

  lifecycle {
    ignore_changes = [user_ids]
  }
}
