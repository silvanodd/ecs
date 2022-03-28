##################
# Common variables
##################

variable "project_name" {
  description = " Project name"
  type        = string
  default     = null
}

variable "region" {
  description = " AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  description = "environment name dev, nonprod, prod"
  type        = string
  default     = null
}


variable "vpc_cidr" {
  default = "10.20.0.0/16"
}

variable "subnets_cidr" {
  type    = list(any)
  default = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
}

variable "azs" {
  type    = list(any)
  default = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

variable "tooling_account" {
  description = "aws tooling accunt number"
  type        = string
  default     = "123456789012"
}
