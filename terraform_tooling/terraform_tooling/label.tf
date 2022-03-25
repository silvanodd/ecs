module "label" {
  source    = "git::https://github.com/cloudposse/terraform-terraform-label.git"
  namespace = var.project_name
  delimiter = "-"
  tags = {
    "environment" = var.environment
  }
}
