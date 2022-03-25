resource "aws_codebuild_project" "my_resource" {

  name           = module.label.id
  service_role   = aws_iam_role.codebuild_service_role.arn
  build_timeout  = 10
  encryption_key = aws_kms_key.my_resource.arn

  source {
    type            = "CODECOMMIT"
    location        = aws_codecommit_repository.my_resource.clone_url_http
    git_clone_depth = 1
    git_submodules_config {
      fetch_submodules = false
    }
    insecure_ssl = false
  }

  source_version = "refs/heads/master"

  artifacts {
    type                   = "S3"
    location               = aws_s3_bucket.my_resource.id
    path                   = ""
    namespace_type         = "NONE"
    name                   = module.label.id
    packaging              = "NONE"
    override_artifact_name = false
    encryption_disabled    = false
  }

  cache {
    type = "NO_CACHE"
  }

  environment {
    type                        = "LINUX_CONTAINER"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    compute_type                = "BUILD_GENERAL1_SMALL"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"
  }

  badge_enabled = false


  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }
    s3_logs {
      status              = "DISABLED"
      encryption_disabled = false
    }
  }

  tags = module.label.tags

}

############################
# Code Build Role and Policy
############################

resource "aws_iam_role" "codebuild_service_role" {
  name = "${module.label.id}_codebuild_service_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "codebuild_service_policy" {
  name        = "${module.label.id}_codebuild_service_policy"
  path        = "/"
  description = "Policy for code build"
  policy      = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${module.label.id}",
                "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${module.label.id}:*"
            ],
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "${aws_s3_bucket.my_resource.arn}*"
            ],
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "${aws_codecommit_repository.my_resource.arn}"
            ],
            "Action": [
                "codecommit:GitPull"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "${aws_s3_bucket.my_resource.arn}",
                "${aws_s3_bucket.my_resource.arn}/*"
            ],
            "Action": [
                "s3:*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codebuild:CreateReportGroup",
                "codebuild:CreateReport",
                "codebuild:UpdateReport",
                "codebuild:BatchPutTestCases",
                "codebuild:BatchPutCodeCoverages"
            ],
            "Resource": [
                "arn:aws:codebuild:${var.region}:${data.aws_caller_identity.current.account_id}:report-group/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "${aws_kms_key.my_resource.arn}"
        }
    ]
}
POLICY
}


resource "aws_iam_role_policy_attachment" "codebuild_service_policy_attachment" {
  role       = aws_iam_role.codebuild_service_role.name
  policy_arn = aws_iam_policy.codebuild_service_policy.arn
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryPowerUserAttachment" {
  role       = aws_iam_role.codebuild_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

