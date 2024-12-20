provider "aws" {
  region = "eu-west-3" 
}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-3a" 
}

resource "aws_security_group" "instance_sg" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "my_instance" {
  ami                         = "ami-00d81861317c2cc1f"  # Remplace par ton AMI
  instance_type               = "t2.micro"
  key_name                    = "myKey" 
  vpc_security_group_ids      = [aws_security_group.instance_sg.id]
  subnet_id                   = aws_subnet.main_subnet.id
  associate_public_ip_address = true 

  tags = {
    Name = "DevOpsProjectInstance"
  }
}

output "instance_ip" {
  value = aws_instance.my_instance.public_ip
}
