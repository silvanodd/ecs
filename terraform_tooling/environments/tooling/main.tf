provider "aws" {
  region = "eu-west-2"
}


module "tooling" {
  source       = "../../"
  environment  = "tooling"
  project_name = "testproject2"
}
