
output "node_address" {
    value = aws_elasticache_cluster.RedisCache.cache_nodes[0].address
    description = "Cluster address"
}
