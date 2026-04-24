variable "aws_region" { default = "ap-southeast-1" }
variable "project_name" { default = "auto-deployment-practice" }
variable "container_port" { default = 5000 }
variable "cpu_units" { default = "256" }
variable "memory_units" { default = "512" }
variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "public_subnet_cidr" { default = "10.0.1.0/24" }