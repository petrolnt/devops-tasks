variable "aws_region" {
  type        = string
  description = "The AWS Region"
  default     = "us-east-2"
}
variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for new VPC"
  default     = "10.10.0.0/16"
}
variable "public_subnets" {
  type        = list(object({
      name = string
      cidr = string
      avalability_zone = string
      public = bool
  }))
  default     = [
      {
          name = "PublicSubnetA"
          cidr = "10.10.0.0/24"
          avalability_zone = "us-east-2a"
          public = true
      },
      {
          name = "PublicSubnetB"
          cidr = "10.10.1.0/24"
          avalability_zone = "us-east-2b"
          public = true
      }
  ]
}
variable "protected_subnets" {
  type        = list(object({
      name = string
      cidr = string
      avalability_zone = string
      public = bool
  }))
  default     = [
      {
          name = "ProtectedSubnetA"
          cidr = "10.10.10.0/24"
          avalability_zone = "us-east-2a"
          public = false
      },
      {
          name = "ProtectedSubnetB"
          cidr = "10.10.11.0/24"
          avalability_zone = "us-east-2b"
          public = false
      }
  ]
}
