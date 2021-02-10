output "vpc_id" {
    value = aws_vpc.new_vpc.id
    description = "VPC ID"
}

output "public_subnets" {
    value = aws_subnet.public_subnets
    description = "Public subnets list"
}

output "protected_subnets" {
    value = aws_subnet.protected_subnets
    description = "Protected subnets list"
}
