#EC2
provider "aws" {
    region = "eu-north-1"
}

resource "aws_instance" "my_instance" {
    ami = "ami-073130f74f5ffb161"
    instance_type = "t3.micro"
    key_name = "ubuntu"
    security_groups = ["sg-07658f9231569eb9b"] 
    tags = {
        Name = "terraform_instance"
    }
}

