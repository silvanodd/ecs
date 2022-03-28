##################
# Common variables
##################

variable "project_name" {
  description = " Project namr"
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
  default     = "null"
}

variable "dev_account_id" {
  description = "aws dev accunt number"
  type        = string
  default     = "123456789012"
}

variable "prod_account_id" {
  description = "aws production accunt number"
  type        = string
  default     = "123456789012"
}
