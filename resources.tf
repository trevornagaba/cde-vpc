resource "aws_instance" "private-instance" {
  ami           = "ami-07caf09b362be10b8"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private-subnet-1.id
  tags = {
    Name = "private-instance"
  }
}

resource "aws_instance" "public-instance" {
  ami           = "ami-04b70fa74e45c3917"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public-subnet-1.id
  tags = {
    Name = "public-instance"
  }
}