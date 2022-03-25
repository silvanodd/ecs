provider "aws" {
  region = "eu-west-2"
}


module "ecs" {
  source       = "../../"
  environment  = "prod"
  project_name = "testproject2"
}
