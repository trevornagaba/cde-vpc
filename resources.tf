locals {
  web_servers = {
    my-app-00 = {
      machine_type = "t2.micro"
      subnet_id    = aws_subnet.private-subnet-1.id
    }
    my-app-01 = {
      machine_type = "t2.micro"
      subnet_id    = aws_subnet.private-subnet-2.id
    }
  }
}


resource "aws_instance" "private-instance" {
  for_each = local.web_servers
  # ami           = "ami-07caf09b362be10b8"
  ami           = "ami-04b70fa74e45c3917"
  instance_type = each.value.machine_type
  subnet_id     = each.value.subnet_id
  key_name      = "cde-vpc"
  tags = {
    Name = "private-instance"
  }
  user_data = <<-EOF
             #!/bin/bash
             sudo apt-get update
             sudo apt-get install -y nginx
             sudo systemctl start nginx
             sudo systemctl enable nginx
             echo '<!doctype html>
             <html lang="en"><h1>Home page!</h1></br>
             <h3>(Instance B >>> in Private Subnet)</h3>
             </html>' | sudo tee /var/www/html/index.html
             EOF

  vpc_security_group_ids = [aws_security_group.ec2_private.id]
}

resource "aws_instance" "public-instance" {
  ami           = "ami-04b70fa74e45c3917"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public-subnet-1.id
  key_name      = "cde-vpc"
  tags = {
    Name = "public-instance"
  }
  vpc_security_group_ids = [aws_security_group.web-sg.id]

  user_data = <<-EOF
             #!/bin/bash
             sudo apt-get update
             sudo apt-get install -y nginx
             sudo systemctl start nginx
             sudo systemctl enable nginx
             echo '<!doctype html>
             <html lang="en"><h1>Home page!</h1></br>
             <h3>(Instance A >>> in Public Subnet)</h3>
             </html>' | sudo tee /var/www/html/index.html
             EOF
}


# Security group for private instance

resource "aws_security_group" "ec2_private" {
  name   = "ec2_private"
  vpc_id = aws_vpc.demo-vpc.id
}

resource "aws_security_group_rule" "ingress_ec2_traffic" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ec2_private.id
  source_security_group_id = aws_security_group.alb_eg1.id
}

resource "aws_security_group_rule" "ingress_ssh_traffic" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.ec2_private.id
  # Allow connection from anywhere for ssh
  cidr_blocks = ["0.0.0.0/0"]
}

# resource "aws_security_group_rule" "ingress_ec2_health_check" {
#   type                     = "ingress"
#   from_port                = 8081
#   to_port                  = 8081
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.ec2_private.id
#   source_security_group_id = aws_security_group.alb_eg1.id
# }

# When you create a security group with terraform, it will automatically remove all egress rules. 
# If your app requires internet access, you can open it with the full_egree_ec2 resource, 
# which is a good starting point.

resource "aws_security_group_rule" "full_egress_ec2" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.ec2_private.id
  cidr_blocks       = ["0.0.0.0/0"]
}
