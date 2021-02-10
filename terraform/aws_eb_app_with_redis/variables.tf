variable "aws_region" {
  type        = string
  description = "The AWS Region"
  default     = "us-east-2"
}
variable "service_name" {
  type    = string
  default = "one"
}
variable "env_name" {
  type    = string
  default = "One-env"
}
variable "service_description" {
  type    = string
  default = "One"
}
variable "load_balancer_type" {
  type    = string
  default = "application"
}
variable "solution_stack" {
  type    = string
  default = "64bit Amazon Linux 2 v5.2.4 running Node.js 12"
}
variable "dns_domain" {
  type    = string
  default = "petrol-nt.net"
}
variable "app_vpc" {
  type    = string
  default = "vpc-096e5a7b58ad054e3"
}
variable "app_subnets" {
  type    = string
  default = "subnet-01751847d52ca301f,subnet-09d9b29ed6883d131,subnet-0edf743bab2c8a797"
}
variable "app_instance_type" {
  type    = string
  default = "t3.micro"
}
variable "app_availability_zones" {
  type    = string
  default = "Any 1"
}
variable "app_min_size" {
  type    = string
  default = "1"
}
variable "app_max_size" {
  type    = string
  default = "1"
}
variable "ssh_key" {
  type    = string
  default = "petrol_work"
}
