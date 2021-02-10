output "vpc_id" {
    value = aws_vpc.new_vpc.id
    description = "VPC ID"
}

locals {
    public_ids_map = {
        for subnet in aws_subnet.public_subnets:
        subnet.tags.Name => join(", ", [subnet.id])
    }
    protected_ids_map = {
        for subnet in aws_subnet.protected_subnets:
        subnet.tags.Name => join(", ", [subnet.id])
    }
    public_ids_list = values(local.public_ids_map)
    protected_ids_list = values(local.protected_ids_map)
}
output "public_subnets" {
    value = local.public_ids_list
    description = "Public subnets list"
}

output "protected_subnets" {
    value = local.protected_ids_list
    description = "Protected subnets list"
}

