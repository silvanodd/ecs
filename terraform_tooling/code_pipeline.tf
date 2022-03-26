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
	"Version": "2012-10-17",
	"Statement": [{
			"Effect": "Allow",
			"Action": [
				"s3:*"
			],
			"Resource": "${aws_s3_bucket.my_resource.arn}/*"
		},
		{
			"Action": [
				"codecommit:GetUploadArchiveStatus",
				"codecommit:UploadArchive",
				"codecommit:GetBranch",
				"codecommit:GetCommit"
			],
			"Effect": "Allow",
			"Resource": "${aws_codecommit_repository.my_resource.arn}"
		},
		{
			"Action": [
				"codebuild:StartBuild",
        "codebuild:BatchGetBuilds"
			],
			"Effect": "Allow",
			"Resource": "${aws_codebuild_project.my_resource.arn}"
		},
		{
			"Action": "sts:AssumeRole",
			"Effect": "Allow",
			"Resource": [
				"arn:aws:iam::${var.dev_account_id}:role/${module.label.id}_code_pipeline_cross_account_role",
				"arn:aws:iam::${var.prod_account_id}:role/${module.label.id}_code_pipeline_cross_account_role"
			]
		}
	]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "codepipeline_role_policy_attachment" {
  role       = aws_iam_role.codepipeline_service_role.name
  policy_arn = aws_iam_policy.codepipeline_service_policy.arn
}
