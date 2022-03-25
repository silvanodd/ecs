resource "aws_vpc" "my_resource" {
  cidr_block         = "10.20.0.0/16"
  enable_dns_support = true
  tags               = { Name = module.label.id }
}

resource "aws_subnet" "my_resource" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.my_resource.id
  cidr_block              = element(var.subnets_cidr, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true
  tags                    = { Name = module.label.id }
}

resource "aws_internet_gateway" "my_resource" {
  vpc_id = aws_vpc.my_resource.id
  tags   = { Name = module.label.id }
}

resource "aws_route_table" "my_resource" {
  vpc_id = aws_vpc.my_resource.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_resource.id
  }
  tags = { Name = module.label.id }
}

resource "aws_route_table_association" "my_resource" {
  count          = length(var.azs)
  subnet_id      = element(aws_subnet.my_resource.*.id, count.index)
  route_table_id = aws_route_table.my_resource.id
}

