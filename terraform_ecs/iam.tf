# #######################################################
# # IAM role used by code pipeline in the tooling account
# #######################################################

resource "aws_iam_role" "code_pipeline_cross_account_role" {
  name               = join("_", [module.label.id, "code_pipeline_cross_account_role"])
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${var.tooling_account}:role/${module.label.id}_codepipeline_service_role"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

  tags = module.label.tags
}

resource "aws_iam_policy" "code_pipeline_cross_account_policy" {
  name        = join("_", [module.label.id, "code_pipeline_cross_account_policy"])
  path        = "/"
  description = "Role used by the tooling account to run codedeploy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "*"
        ],
        "Resource" : "*"
      },
        {
            "Action": [
                "kms:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },      
    ]
  })
}

resource "aws_iam_role_policy_attachment" "code_pipeline_cross_account_policy_attachment" {
  role       = aws_iam_role.code_pipeline_cross_account_role.name
  policy_arn = aws_iam_policy.code_pipeline_cross_account_policy.arn
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRoleForECS" {
  role       = aws_iam_role.code_pipeline_cross_account_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}


