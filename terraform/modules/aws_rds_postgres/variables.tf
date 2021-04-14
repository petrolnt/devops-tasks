variable "aws_region" {
  type        = string
  description = "The AWS Region"
  default     = "us-east-2"
}
# RDS common properties
variable "name" {
  type = string
  description = "The database instance name"
  default = "test-db"
}
variable "tags" {
  type = map
  default = {
    Owner       = "user"
    Environment = "dev"
  }
}
# VPC properties
variable "rds_vpc_cidr" {
  type = string
  default = "10.99.0.0/18"
}
variable "public_subnets" {
  type = list
  default = ["10.99.0.0/24", "10.99.1.0/24", "10.99.2.0/24"]
}
variable "private_subnets" {
  type = list
  default = ["10.99.3.0/24", "10.99.4.0/24", "10.99.5.0/24"]
}
variable "database_subnets" {
  type = list
  default = ["10.99.7.0/24", "10.99.8.0/24", "10.99.9.0/24"]
}
variable "create_db_subnet_group" {
  type = bool
  default = true
}
# RDS DB properties
variable "db_name" {
  type = string
  default = "TestDB"
}
variable "db_username" {
  type = string
  default = "awsroot"
}
variable "db_password" {
    type = string
}
variable "db_port" {
  type = number
  default = 5432
}
variable "db_engine_version" {
  type = string
  default = "12.5"
}
variable "db_family" {
  type = string
  default = "postgres12" # DB parameter group
}
variable "db_major_engine_version" {
  type = string
  default = "12"         # DB option group
}
variable "db_instance_class" {
  type = string
  default = "db.t3.micro"
}
variable "db_allocated_storage" {
  type = number
  default = 20
}
variable "db_max_allocated_storage" {
  type = string
  default = 100
}
variable "db_storage_encrypted" {
  type = bool
  default = false
}
variable "db_backup_retention_period" {
  type = number
  default = 30
}
variable "db_deletion_protection" {
  type = bool
  default = false
}