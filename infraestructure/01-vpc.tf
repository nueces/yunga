resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = merge(
    var.default_tags, {
      Name = "${local.configuration.project_name} VPC"
  })

}


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.default_tags, {
      Name = "${local.configuration.project_name} Internet Gateway"
  })
}


resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr_block
  availability_zone = local.defaults.availability_zone

  tags = merge(
    var.default_tags, {
      Name = "${local.configuration.project_name} Public Subnet"
  })
}


resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_block
  availability_zone = local.defaults.availability_zone

  tags = merge(
    var.default_tags, {
      Name = "${local.configuration.project_name} Private Subnet"
  })
}



# By default the IGW has a routing table that doesn't allow public traffic, so we need to add a public one
# to allow traffic from the internet to public_subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(
    var.default_tags, {
      Name = "${local.configuration.project_name} Public Routing Table"
  })
}


resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

#resource "aws_route_table_association" "private" {
#  subnet_id      = aws_subnet.private.id
#  route_table_id = aws_route_table.main.id
#}


resource "aws_security_group" "public" {
  name        = "${local.configuration.project_name} Public Security Group"
  description = "Manage inbound/outbound traffic for ${local.configuration.project_name} Public Network"

  vpc_id = aws_vpc.main.id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.default_tags, {
      Name = "${local.configuration.project_name} Public Security Group"
  })

}


resource "aws_vpc_security_group_ingress_rule" "public" {
  for_each = { for each in var.public_ingress_rules : each.name => each }

  security_group_id = aws_security_group.public.id
  description       = each.value.description
  cidr_ipv4         = each.value.cidr_ipv4
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"

  tags = merge(
    var.default_tags, {
      Name = "Public Ingress rule ${each.key}"
  })
}


resource "aws_vpc_security_group_egress_rule" "public" {

  security_group_id = aws_security_group.public.id
  description       = "outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = merge(
    var.default_tags, {
      Name = "Public Egress rule"
  })
}


# NAT IP
resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.gw]
}


resource "aws_nat_gateway" "private" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = merge(
    var.default_tags, {
      Name = "NAT Gateway for ${local.configuration.project_name} Private Network"
  })
}


# Routing tables to route traffic for Private Subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.private.id
  }

  tags = merge(
    var.default_tags, {
      Name = "${local.configuration.project_name} Private Routing Table"
  })
}

#resource "aws_route" "private_nat_gateway" {
#  route_table_id         = aws_route_table.private.id
#  destination_cidr_block = "0.0.0.0/0"
#  nat_gateway_id         = aws_nat_gateway.nat.id
#}


resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}


resource "aws_security_group" "private" {
  name        = "${local.configuration.project_name} Private Security Group"
  description = "Manage inbound/outbound traffic for ${local.configuration.project_name} Private Network"

  vpc_id = aws_vpc.main.id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.default_tags, {
      Name = "${local.configuration.project_name} Private Security Group"
  })

}


resource "aws_vpc_security_group_ingress_rule" "private" {
  for_each = { for each in var.private_ingress_rules : each.name => each }

  security_group_id = aws_security_group.private.id
  description       = each.value.description
  cidr_ipv4         = coalesce(each.value.cidr_ipv4, join("/", [aws_instance.frontend.private_ip, "32"]))
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"

  tags = merge(
    var.default_tags, {
      Name = "Private Ingress rule ${each.key}"
  })
}


resource "aws_vpc_security_group_egress_rule" "private" {

  security_group_id = aws_security_group.private.id
  description       = "outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = merge(
    var.default_tags, {
      Name = "Private Egress rule"
  })
}


# TODO: A security group accepting traffic only from the Dashboard VM.