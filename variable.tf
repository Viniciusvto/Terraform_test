variable "instance_name" {
  description = "The name of the EC2 instance"
  type        = string
  default     = "Learn-terraform"
}

variable "instance_type" {
  description = "The type of the EC2 instance"
  type        = string
  default     = "t3.micro"
}
