 terraform{
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = ">= 2.60.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-north-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = {
    Name = "HelloWorld"
  }
}

data "aws_ami" "spotEc2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}

resource "aws_instance" "web2" {
  ami = data.aws_ami.spotEc2.id
  instance_type = "t4g.nano"
   
  tags = {
    Name = "test-spot"
  }
}

# =========================Day 2 ==============================

# Creating security group that allows public access to the ec2 instance 
# Attach this group to cerated ec2 amchine to acheive public access

resource "aws_security_group" "public_http" {
  name        = "public-http"
  description = "Allow HTTP access from anywhere"

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

# Creating ec2 spot instance with attaching security group
# to create spot instance, aws version must be greater than 2.60.0 
# although spot_option instance_intrupption_behavior was not working as expected
# the index.html file location must be specfice while providing user data
# to view the index.html, copy and paste the public ip manually

resource "aws_instance" "spot_hello_html" {
  ami           = "ami-0c4fc5dcabc9df21d" 
  instance_type = "t3.micro"
  
  instance_market_options {
    market_type = "spot"
    spot_options {
      instance_interruption_behavior = "terminate"
    }
  }


  user_data = <<-EOF
    #!/bin/bash
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<html><body>Hello World</body></html>" > /var/www/html/index.html
  EOF
  
  vpc_security_group_ids = [aws_security_group.public_http.id]

  tags = {
    Name = "SpotHelloWorldHTML"
  }
}
