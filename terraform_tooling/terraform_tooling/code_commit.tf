resource "aws_codecommit_repository" "my_resource" {
  repository_name = module.label.id
  description     = "This is the ${module.label.id} Repository"
}




resource "aws_iam_policy" "codecommit_user_policy" {
  name        = "${module.label.id}_codecommit_user_policy"
  path        = "/"
  description = "Policy to allow user access to repository, attach policy to user permissions"
  policy      = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codecommit:*"
            ],
            "Resource": "${aws_codecommit_repository.my_resource.arn}"
        }
    ]
}
POLICY
}
