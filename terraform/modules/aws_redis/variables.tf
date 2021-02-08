variable "aws_region" {
  type        = string
  description = "The AWS Region"
  default     = "us-east-2"
}
variable "cluster_id" {
  type        = string
  default     = "redis-cache"
}
variable "cluster_engine" {
  type        = string
  default     = "redis"
}
variable "node_type" {
  type        = string
  default     = "cache.t3.micro"
}
variable "num_cache_nodes" {
  type        = number
  default     = 1
}
variable "parameter_group" {
  type        = string
  default     = "default.redis6.x"
}
variable "engine_version" {
  type        = string
  default     = "6.0.5"
}
variable "tcp_port" {
  type        = number
  default     = 6379
}
