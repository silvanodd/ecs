provider "aws" {
  region = "eu-west-2"
}


module "ecs" {
  source       = "../../"
  environment  = "dev"
  project_name = "testproject2"
}
