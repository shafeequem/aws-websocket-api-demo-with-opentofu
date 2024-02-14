resource "aws_vpc" "main" {
  cidr_block = var.base_cidr_block
   tags = {
    Name = "tofu-vpc"
  }
}

resource "aws_subnet" "az" {
  count = length(var.availability_zones)
  availability_zone = var.availability_zones[count.index]
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index+1)
}