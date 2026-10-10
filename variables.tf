variable "region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "db_name" {
  type    = string
  default = "wordpress"
}

variable "db_username" {
  type    = string
  default = "wp_user"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "instance_profile_name" {
  type    = string
  default = "awsec2ssm"
}