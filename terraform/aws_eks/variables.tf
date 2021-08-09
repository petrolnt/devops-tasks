variable "aws_region" {
    type        = string
    description = "The AWS Region"
    default     = "us-east-2"
}
variable "cluster_name" {
    type    = string
    default = "test-eks"
}
variable "nodegroup_name" {
    type    = string
    default = "NodeGroup01"
}
variable "nodegroup_size" {
    type    = string
    default = "2"
}
variable "node_instance_type" {
    type    = string
    default = "t3.micro"
}
variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))

  default = [
    {
      userarn  = "arn:aws:iam::981435086508:user/devops"
      username = "devops"
      groups   = ["system:masters"]
    },
  ]
}


