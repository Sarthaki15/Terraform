#EC2
provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "my_instance" {
    ami = "ami-0b6c6ebed2801a5cb"
    instance_type = "t3.micro"
    key_name = "ubuntu"
    security_groups = ["sg-04cd3dac63c3d9587"] 
    tags = {
        Name = "terraform_instance"
    }
}

#s3 bucket

provider "aws" {
    region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_bucket" {
  bucket = "my-terraform-s3-bucket-0381"
}


#create new security groupand attach it to instance
provider "aws" {
    region = "us-east-1"
}

data "aws_vpc" "default" {
    default = "true"
}

resource "aws_security_group" "terraform_security_group" {
    name = "terraform_sg"
    description = "created using terraform"
    vpc_id = data.aws_vpc.default.id


    ingress {
        from_port = 22
        to_port = 22
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "terraform_sg_instance" {
    instance_type = "t3.micro"
    ami = "ami-0b6c6ebed2801a5cb"
    key_name = "ubuntu"
    tags = {
      Name = "terraform_instance"
    }
    vpc_security_group_ids = [aws_security_group.terraform_security_group.id]
}



# Ec2 instance with user data of nginx

provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "terraform_instance" {
    ami = "ami-0b6c6ebed2801a5cb"
    instance_type = "t3.micro"
    key_name = "ubuntu"
    vpc_security_group_ids = ["sg-04cd3dac63c3d9587"]
    tags = {
      Name = "usr_data_instance"
    }
    user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install nginx -y
    systemctl start nginx
    systemctl enable nginx
    EOF
    
}
output "public_ip" {
  value = aws_instance.terraform_instance.public_ip
}




provider "aws" {
    region = var.region
}

resource "aws_instance" "var-ec2" {
    ami = var.ami
    instance_type = var.instance_type
    key_name = var.key_name
    tags = {
      Name = "var-ec2"
    }
}

variable "region" {
    type = string
    default = "us-east-1"
}

variable "ami" {
    type = string
    default = "ami-0b6c6ebed2801a5cb"
}

variable "instance_type" {
    type = string
    default = "t3.micro"
}

variable "key_name" {
    type = string
    default = "ubuntu"
}

output "aws_instance" {
    value = aws_instance.var-ec2.id
}

output "instance_ip" {
    value = aws_instance.var-ec2.public_ip
}
