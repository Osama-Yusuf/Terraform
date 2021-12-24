provider "aws" {
    profile = "default"
    region  = "us-west-2"
}

resource "aws_s3_bucket" "prod_tf_course" { 
    bucket = "tf-course-osama-2022"
    acl    = "private"
}

resource "aws_default_vpc" "default" {}

# resource "aws_instance" "ubuntu" {
#     ami           = "ami-830c94e3"
#     instance_type = "t2.micro"
# }
