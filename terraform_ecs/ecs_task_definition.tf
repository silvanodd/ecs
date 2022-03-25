resource "aws_ecs_task_definition" "my_resource" {
  family                   = module.label.id
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
  cpu                      = 1024
  memory                   = 2048

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = null
  }

  container_definitions = jsonencode([
    {
      name      = join("_", [module.label.id, "container"])
      image     = "${var.tooling_account}.dkr.ecr.${var.region}.amazonaws.com/${module.label.id}:latest"
      essential = true
      environment = [
        {
          "name" : "message",
          "value" : "message"
        }
      ],
      logConfiguration = {
        logDriver     = "awslogs",
        secretOptions = null,
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_task_definition.name,
          awslogs-region        = var.region,
          awslogs-stream-prefix = "ecs"
        }
      },
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp",
        }
      ]
    }
  ])

  tags = module.label.tags

}


###############################
# IAM execution role
###############################

resource "aws_iam_role" "execution_role" { 
  name               = join("_", [module.label.id, "execution_role"])
  description = "The role that authorizes Amazon ECS to pull private images and publish logs for your task. "
  assume_role_policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

  tags = module.label.tags
}

resource "aws_iam_policy" "execution_policy" {
  name        = join("_", [module.label.id, "execution_policy"])
  description = "The policy that authorizes Amazon ECS to pull private images and publish logs for your task. "
  path        = "/"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRolePolicyAttachment" {
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.execution_policy.arn
}

#############################################################################################################################
# IAM role task_definition_role, this is not actually used by the task definition in this project, it is here for reference.
#############################################################################################################################

resource "aws_iam_role" "task_role" {
  name               = join("_", [module.label.id, "task_role"])
  description = "IAM role that tasks can use to make API requests to authorized AWS services."
  assume_role_policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

  tags = module.label.tags
}

resource "aws_iam_policy" "task_policy" {
  name        = join("_", [module.label.id, "task_policy"])
  description = "IAM policy that tasks can use to make API requests to authorized AWS services."
  path        = "/"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeInstances",
          "ec2:DescribeImages",
          "ec2:DescribeTags",
          "ec2:DescribeSnapshots"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_policy_attachment" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_policy.arn
}