resource "aws_vpc" "demo-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "demo-vpc"
  }
}

resource "aws_subnet" "private-subnet-1" {
  vpc_id            = aws_vpc.demo-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private-subnet-2" {
  vpc_id            = aws_vpc.demo-vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private-subnet-2"
  }
}

resource "aws_subnet" "public-subnet-1" {
  vpc_id            = aws_vpc.demo-vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public-subnet-2" {
  vpc_id            = aws_vpc.demo-vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-2"
  }
}

resource "aws_internet_gateway" "demo-igw" {
  vpc_id = aws_vpc.demo-vpc.id
  tags = {
    Name = "demo-vpc-IGW"
  }
}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.demo-vpc.id
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route" "public-route" {
  route_table_id         = aws_route_table.public-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.demo-igw.id
}

resource "aws_route_table_association" "public-subnet-1-association" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_route_table_association" "public-subnet-2-association" {
  subnet_id      = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.public-route-table.id
}

# To enable connectivity in the private subnets, you need to create a NAT 
# (Network Address Translation) gateway and associate it with the private subnets. 
# Then you need to attach the NAT Gateway to an Elastic IP Address (EIP).
# An EIP is essential for obtaining a static and public IP address that 
# remains associated with your AWS account. 
# This EIP serves as a consistent endpoint for various resources such as EC2 instances, 
# NAT gateways, or load balancers. Even if these resources are stopped or restarted, 
# the EIP ensures there are no IP address changes or service interruptions, allowing for uninterrupted access to your resources.
# A public NAT gateway uses an elastic IP address to provide it with a public IP address that doesn't change. 
# Note that the route table for the public subnet with the NAT gateway must also have a route that sends all 
# internet-bound traffic to an internet gateway, so that the NAT gateway can connect to the internet.

resource "aws_eip" "nat-eip-1" {
  domain = "vpc"
  tags = {
    Name = "nat-eip-1"
  }
}

resource "aws_eip" "nat-eip-2" {
  domain = "vpc"
  tags = {
    Name = "nat-eip-2"
  }
}

resource "aws_nat_gateway" "nat-gateway-1" {
  allocation_id = aws_eip.nat-eip-1.id
  subnet_id     = aws_subnet.public-subnet-1.id
  tags = {
    Name = "nat-gateway-1"
  }
  depends_on = [aws_internet_gateway.demo-igw]
}

resource "aws_nat_gateway" "nat-gateway-2" {
  allocation_id = aws_eip.nat-eip-2.id
  subnet_id     = aws_subnet.public-subnet-2.id
  tags = {
    Name = "nat-gateway-2"
  }
  depends_on = [aws_internet_gateway.demo-igw]
}

# The route tables to associate private subnets with NAT Gateway.

resource "aws_route_table" "private-route-table-1" {
  vpc_id = aws_vpc.demo-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gateway-1.id
  }

  tags = {
    Name = "private-1"
  }
}

resource "aws_route_table" "private-route-table-2" {
  vpc_id = aws_vpc.demo-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gateway-2.id
  } 
  tags = {
    Name = "private-2"
  }
}

resource "aws_route_table_association" "private-subnet-1-association" {
  subnet_id      = aws_subnet.private-subnet-1.id
  route_table_id = aws_route_table.private-route-table-1.id
}

resource "aws_route_table_association" "private-subnet-2-association" {
  subnet_id      = aws_subnet.private-subnet-2.id
  route_table_id = aws_route_table.private-route-table-2.id
}



resource "aws_security_group" "web-sg" {
  vpc_id = aws_vpc.demo-vpc.id
  name   = "web-sg"

  ingress = [{
    description      = "http traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
    }, {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

resource "aws_security_group" "db-sg" {
  vpc_id = aws_vpc.demo-vpc.id
  name   = "db-sg"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
    # Allow traffic from private subnets
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}
