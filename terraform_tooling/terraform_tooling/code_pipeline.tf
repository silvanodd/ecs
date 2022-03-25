resource "aws_codepipeline" "my_resource" {
  name     = module.label.id
  role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${module.label.id}_codepipeline_service_role"
  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.my_resource.bucket
  }
  stage {
    name = "Source"
    action {
      name             = "CodeCommit_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      run_order        = 1
      input_artifacts  = []
      output_artifacts = ["SourceArtifact"]
      region           = var.region
      namespace        = "SourceVariables"
      configuration = {
        BranchName           = "master"
        OutputArtifactFormat = "CODE_ZIP"
        PollForSourceChanges = "false"
        RepositoryName       = module.label.id
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Application_Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      run_order        = 1
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["Artifact1"]
      region           = "eu-west-2"
      namespace        = "BuildVariables"
      configuration = {
        ProjectName = module.label.id
      }
    }
  }

  stage {
    name = "Deploy_to_Dev"
    action {
      provider = "CodeDeployToECS"
      name     = "Deploy_to_Dev"
      role_arn         = "arn:aws:iam::${var.dev_account_id}:role/${module.label.id}_code_pipeline_cross_account_role"
      region           = "eu-west-2"
      namespace        = "DeployVariables"
      run_order        = 1
      output_artifacts = []
      input_artifacts  = ["Artifact1"]
      category         = "Deploy"
      owner            = "AWS"
      version          = "1"
      configuration = {
        "ApplicationName"                = module.label.id
        "DeploymentGroupName"            = module.label.id
        "AppSpecTemplateArtifact"        = "Artifact1"
        "AppSpecTemplatePath"            = "appspec_dev.yaml"
        "TaskDefinitionTemplateArtifact" = "Artifact1"
        "TaskDefinitionTemplatePath"     = "taskdef_dev.json"
        "Image1ArtifactName"             = "Artifact1"
        "Image1ContainerName"            = "IMAGE_NAME"
      }
    }
  }

  stage {
    name = "Deploy_to_Prod"
    action {
      provider = "CodeDeployToECS"
      name     = "Deploy_to_Prod"
      role_arn         = "arn:aws:iam::${var.prod_account_id}:role/${module.label.id}_code_pipeline_cross_account_role"
      region           = "eu-west-2"
      run_order        = 1
      output_artifacts = []
      input_artifacts  = ["Artifact1"]
      category         = "Deploy"
      owner            = "AWS"
      version          = "1"
      configuration = {
        "ApplicationName"                = module.label.id
        "DeploymentGroupName"            = module.label.id
        "AppSpecTemplateArtifact"        = "Artifact1"
        "AppSpecTemplatePath"            = "appspec_prod.yaml"
        "TaskDefinitionTemplateArtifact" = "Artifact1"
        "TaskDefinitionTemplatePath"     = "taskdef_prod.json"
        "Image1ArtifactName"             = "Artifact1"
        "Image1ContainerName"            = "IMAGE_NAME"
      }
    }
  }

}

###############################
# Code Pipeline Role and Policy
###############################

resource "aws_iam_role" "codepipeline_service_role" {
  name = "${module.label.id}_codepipeline_service_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "codepipeline_service_policy" {
  name        = "${module.label.id}_codepipeline_service_policy"
  path        = "/"
  description = "Policy for code pipeline"
  policy      = <<POLICY
{
    "Statement": [
        {
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Condition": {
                "StringEqualsIfExists": {
                    "iam:PassedToService": [
                        "cloudformation.amazonaws.com",
                        "elasticbeanstalk.amazonaws.com",
                        "ec2.amazonaws.com",
                        "ecs-tasks.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Action": [
                "codecommit:CancelUploadArchive",
                "codecommit:GetBranch",
                "codecommit:GetCommit",
                "codecommit:GetRepository",
                "codecommit:GetUploadArchiveStatus",
                "codecommit:UploadArchive"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codedeploy:CreateDeployment",
                "codedeploy:GetApplication",
                "codedeploy:GetApplicationRevision",
                "codedeploy:GetDeployment",
                "codedeploy:GetDeploymentConfig",
                "codedeploy:RegisterApplicationRevision"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codestar-connections:UseConnection"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "elasticbeanstalk:*",
                "ec2:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "cloudwatch:*",
                "s3:*",
                "sns:*",
                "cloudformation:*",
                "rds:*",
                "sqs:*",
                "ecs:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "lambda:InvokeFunction",
                "lambda:ListFunctions"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "opsworks:CreateDeployment",
                "opsworks:DescribeApps",
                "opsworks:DescribeCommands",
                "opsworks:DescribeDeployments",
                "opsworks:DescribeInstances",
                "opsworks:DescribeStacks",
                "opsworks:UpdateApp",
                "opsworks:UpdateStack"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "cloudformation:CreateStack",
                "cloudformation:DeleteStack",
                "cloudformation:DescribeStacks",
                "cloudformation:UpdateStack",
                "cloudformation:CreateChangeSet",
                "cloudformation:DeleteChangeSet",
                "cloudformation:DescribeChangeSet",
                "cloudformation:ExecuteChangeSet",
                "cloudformation:SetStackPolicy",
                "cloudformation:ValidateTemplate"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild",
                "codebuild:BatchGetBuildBatches",
                "codebuild:StartBuildBatch"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Effect": "Allow",
            "Action": [
                "devicefarm:ListProjects",
                "devicefarm:ListDevicePools",
                "devicefarm:GetRun",
                "devicefarm:GetUpload",
                "devicefarm:CreateUpload",
                "devicefarm:ScheduleRun"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "servicecatalog:ListProvisioningArtifacts",
                "servicecatalog:CreateProvisioningArtifact",
                "servicecatalog:DescribeProvisioningArtifact",
                "servicecatalog:DeleteProvisioningArtifact",
                "servicecatalog:UpdateProduct"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:ValidateTemplate"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:DescribeImages"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "states:DescribeExecution",
                "states:DescribeStateMachine",
                "states:StartExecution"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "appconfig:StartDeployment",
                "appconfig:StopDeployment",
                "appconfig:GetDeployment"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Resource": [
                "${aws_s3_bucket.my_resource.arn}",
                "${aws_s3_bucket.my_resource.arn}/*"
            ],
            "Action": [
                "s3:PutObject",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
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
        },
        {
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Resource": [
                "arn:aws:iam::${var.dev_account_id}:role/${module.label.id}_code_pipeline_cross_account_role",
                "arn:aws:iam::${var.prod_account_id}:role/${module.label.id}_code_pipeline_cross_account_role"
                ]
        }
    ],
    "Version": "2012-10-17"
}
POLICY
}

resource "aws_iam_role_policy_attachment" "codepipeline_role_policy_attachment" {
  role       = aws_iam_role.codepipeline_service_role.name
  policy_arn = aws_iam_policy.codepipeline_service_policy.arn
}
