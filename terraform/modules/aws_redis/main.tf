provider "aws" {
  region = var.aws_region
}

resource "aws_elasticache_subnet_group" "subnet_group" {
  name       = "cache-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "redis_sg" {
  name        = "redis_sg"
  description = "Allow redis inbound traffic"
  vpc_id      = var.vpc

  ingress {
    description = "Allow Redis"
    from_port   = var.tcp_port
    to_port     = var.tcp_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow redis"
  }
}



resource "aws_elasticache_cluster" "RedisCache" {
  cluster_id           = var.cluster_id
  engine               = var.cluster_engine
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes
  parameter_group_name = var.parameter_group
  port                 = var.tcp_port
  subnet_group_name = aws_elasticache_subnet_group.subnet_group.name
  security_group_ids = [ aws_security_group.redis_sg.id ]
  #num_node_groups = 1
}
