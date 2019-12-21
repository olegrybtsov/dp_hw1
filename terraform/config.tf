provider "aws" {
  profile = "default"
  region  = "eu-central-1"
}

//resource "aws_instance" "example" {
//  ami           = "ami-0d4c3eabb9e72650a"
//  instance_type = "t2.micro"
//}

resource "aws_ebs_volume" "hdd" {
  availability_zone = "eu-central-1a"
  size              = 500
  type = "sc1"

  tags = {
    Name = "HDD"
  }
}

resource "aws_ebs_volume" "ssd" {
  availability_zone = "eu-central-1a"
  size              = 10
  type = "gp2"

  tags = {
    Name = "SSD"
  }
}