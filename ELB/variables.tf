variable "key_name" {
    type= "string"
    description = "The Key used to SSH into the EC2 instance."
  
}

variable "aws_region" {
  type="string"
  default="us-east-1"
}

variable "VPC_cidr" {
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  default = "10.0.0.0/24"
}

variable "aws_amis" {
  default = {
    "us-east-1" = "ami-5f709f34"
    "us-west-2" = "ami-7f675e4f"
  }
}