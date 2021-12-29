variable "whitelist" {
  type = list(string)
}
variable "web_image_id" {
  type = string
}
variable "web_instance_type" {
  type = string
}
variable "web_desired_capacity" {
  type = number
}
variable "web_max_size" {
  type = number
}
variable "web_min_size" {
  type = number
}


/* -------------------------------- variables ------------------------------- */ # Variables are not that handy they are good for learning

# variable "web_ami" {
  # type  = string
  # default = "ami-abc123"
# }

# resource "aws_instance" "web" {
  # ami           = var.web_ami  # or "${var.web_ami}"
  # instance_type = "t2.micro"
# }

# --- as you can override the var value in the command line like this:
# --- terraform apply -var web_ami=ami-def456

/* -------------------------------- variables ------------------------------- */

/* ---------------------------------------------------------------------------------------------------------------- */

/* ------------------------------ Data Sources ------------------------------ */  # Data Sources are like variables, but they retrive data from AWS or other terraform configuration

# --------------------------------- Examble One --------------------------------- 

# data "aws_ami" "web_ami" {
  # most_recent = true
  # owners      = ["self"]

  # tags = {
    # Name   = "webserver"
    # Deploy = "true"
  # }
# }

# resource "aws_instance" "web" {
  # ami = data.aws_ami.web_ami.id
# }

# --------------------------------- Examble Two --------------------------------- 

# data "aws_ami" "ubuntu" {
  # most_recent = true
  # filter {
    # name   = "name"
    # values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  # }
  # filter {
    # name   = "virtualization-type"
    # values = ["hvm"]
  # }
  # owners      = ["099720109477"] # 099720109477 is Canonical
# }

/* ------------------------------ Data Sources ------------------------------ */

/* ---------------------------------------------------------------------------------------------------------------- */

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

resource "aws_s3_bucket" "prod_tf_course" { 
  bucket = "tf-course-osama-2022"
  acl    = "private"
  tags = {
    "Terraform" : "true"
  }
}

resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-west-2a"
  tags = {
    "Terraform" : "true"
  }
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = "us-west-2b"
  tags = {
    "Terraform" : "true"
  }
}

resource "aws_security_group" "prod_web" {
  name        = "prod_web"
  description = "Allow standard http and https ports inbount and all outbound"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp" 
    cidr_blocks = var.whitelist
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp" 
    cidr_blocks = var.whitelist
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Terraform" : "true"
  }
}

# -------------------------- commented the next block to creaete an auto scaling group
# resource "aws_instance" "prod_web" {
#   count         = 2

#   ami           = "ami-0f129ae03ee4c74a0"
#   instance_type = "t2.nano"
  
#   vpc_security_group_ids = [
#     aws_security_group.prod_web.id
#   ]

#     tags = {
#       "Terraform" : "true"
#   }
# }

# resource "aws_eip_association" "prod_web" {
#   instance_id   = aws_instance.prod_web.0.id # or instance_id   = aws_instance.prod_web[0].id  this refere to the first instance 
#   allocation_id = aws_eip.prod_web.id
# }

# resource "aws_eip" "prod_web" {
#   # instance = aws_instance.prod_web.id
#     tags = {
#       "Terraform" : "true"
#   }
# }

resource "aws_elb" "prod_web" {
  name            = "prod-web"
  # instances       = aws_instance.prod_web.*.id # or instances = aws_instance.prod_web[0].id  # now exisisting in the auto scaling group
  subnets         = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  security_groups = [aws_security_group.prod_web.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  tags  = {
    "Terraform" : "true"
  }
}

resource "aws_launch_template" "prod_web" {
  name_prefix   = "prod-web"
  image_id      = var.web_image_id
  instance_type = var.web_instance_type
}

resource "aws_autoscaling_group" "prod_web" {
  # vpc_zone_identifier = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  availability_zones  = ["us-west-2a", "us-west-2b"]
  desired_capacity    = var.web_desired_capacity
  max_size            = var.web_max_size
  min_size            = var.web_min_size

  launch_template {
    id      = aws_launch_template.prod_web.id
    version = "$Latest"
  }
  tag {
    key                 = "Terraform"
    value               = "true"
    propagate_at_launch = true
  }
}

# Create a new load balancer attachment
resource "aws_autoscaling_attachment" "prod_web" {
  autoscaling_group_name = aws_autoscaling_group.prod_web.id
  elb                    = aws_elb.prod_web.id
}
