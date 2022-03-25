resource "aws_ecr_repository" "my_resource" {
  name = module.label.id
}

resource "aws_ecr_repository_policy" "my_resource" {
  repository = aws_ecr_repository.my_resource.name

  policy = <<EOF
{
	"Version": "2008-10-17",
	"Statement": [{
		"Sid": "new policy",
		"Effect": "Allow",
		"Principal": {
			"AWS": ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${module.label.id}_codebuild_service_role",
				"arn:aws:iam::${var.dev_account_id}:role/${module.label.id}_execution_role",
				"arn:aws:iam::${var.prod_account_id}:role/${module.label.id}_execution_role"
			]
		},
		"Action": "ecr:*"
	}]
}
EOF
}