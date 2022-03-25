provider "aws" {
  region = "eu-west-2"
}


module "tooling" {
  source       = "../../"
  environment  = "dev"
  project_name = "testproject2"
}
