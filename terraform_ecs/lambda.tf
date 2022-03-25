

######################################################
# Lambda function to perform simple http response test
######################################################

data "archive_file" "my_resource" {
  type        = "zip"
  source_file  = "${path.module}/lambda_code/AfterAllowTestTraffic.py"
  output_path = "AfterAllowTestTraffic.zip"
}

resource "aws_lambda_function" "AfterAllowTestTraffic" {
  filename         = "AfterAllowTestTraffic.zip" 
  source_code_hash = data.archive_file.my_resource.output_base64sha256
  function_name    = "AfterAllowTestTraffic"
  description      = "AfterAllowTestTraffic"
  handler          = "AfterAllowTestTraffic.lambda_handler"
  role             = aws_iam_role.lambda_execution_role.arn
  runtime          = "python3.8"

  environment {
    variables = {
      load_balancer = aws_lb.my_resource.dns_name
    }
  }
}

###################################
# IAM Roles and Policies for Lambda
###################################

resource "aws_iam_role" "lambda_execution_role" {
  name = join("_", [module.label.id, "lambda_execution_role"])

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_execution_policy" {
  name        = join("_", [module.label.id, "lambda_execution_policy"])
  path        = "/"
  description = "Allow Lambda to PutLifecycleEventHookExecutionStatus"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "codedeploy:PutLifecycleEventHookExecutionStatus"
        ],
        "Resource" : "*"
      },
      {
          "Effect": "Allow",
          "Action": [
              "logs:DescribeLogStreams",
              "logs:GetLogEvents",
              "logs:FilterLogEvents"
          ],
          "Resource": "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
}



