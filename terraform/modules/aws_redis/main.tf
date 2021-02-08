provider "aws" {
  region = var.aws_region
}

resource "aws_elasticache_cluster" "RedisCache" {
  cluster_id           = var.cluster_id
  engine               = var.cluster_engine
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes
  parameter_group_name = var.parameter_group
  engine_version       = var.engine_version
  port                 = var.tcp_port
}
