##############
# Data sources 
##############

data "aws_caller_identity" "current" {}

data "aws_subnets" "my_resource" {
  filter {
    name   = "tag:Name"
    values = ["${module.label.id}"]
  }
}

