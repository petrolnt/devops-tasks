provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "new_vpc" {
    cidr_block = var.vpc_cidr_block
    enable_dns_support = "true"
    enable_dns_hostnames = "true"
    enable_classiclink = "false"
    instance_tenancy = "default"    
}
resource "aws_subnet" "public_subnets" {
    for_each = { for subnet  in var.public_subnets : subnet.name => subnet}
    vpc_id = aws_vpc.new_vpc.id
    cidr_block = each.value.cidr
    map_public_ip_on_launch = true
    availability_zone = each.value.avalability_zone

    tags = {
        Name = each.value.name
    }
}

resource "aws_subnet" "protected_subnets" {
    for_each = { for subnet  in var.protected_subnets : subnet.name => subnet}
    vpc_id = aws_vpc.new_vpc.id
    cidr_block = each.value.cidr
    map_public_ip_on_launch = true
    availability_zone = each.value.avalability_zone

    tags = {
        Name = each.value.name
    }
}

resource "aws_internet_gateway" "new_igw" {
    vpc_id = aws_vpc.new_vpc.id
    
}
resource "aws_route_table" "new_public_rt" {
    vpc_id = aws_vpc.new_vpc.id
    
    route {
        cidr_block = "0.0.0.0/0" 
        gateway_id = aws_internet_gateway.new_igw.id
    }
}
resource "aws_route_table_association" "public_subnet_association"{
    for_each = { for subnet  in aws_subnet.public_subnets : subnet.tags.Name => subnet}
    subnet_id = each.value.id
    route_table_id = aws_route_table.new_public_rt.id
}


