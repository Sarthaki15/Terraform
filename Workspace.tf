provider "aws" {
    region = "us-east-1"
}

resource "aws_s3_bucket" "workspace-bucket" {
    bucket = "my-terraform-s3-bucket-workspace-${terraform.workspace}"
   
    tags = {
        Name = "workspace-bucket"
    }
}


provider "aws" {
    region = "us-east-1"
}

