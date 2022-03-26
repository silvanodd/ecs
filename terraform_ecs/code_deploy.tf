resource "aws_codedeploy_app" "my_resource" {
  compute_platform = "ECS"
  name             = module.label.id
}

resource "aws_codedeploy_deployment_group" "my_resource" {
  app_name               = aws_codedeploy_app.my_resource.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = module.label.id
  service_role_arn       = aws_iam_role.codedeploy_service_role.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }




  dynamic "blue_green_deployment_config" {
    for_each = var.environment != "dev" ? [] : [1]
    content {
      deployment_ready_option {
        action_on_timeout    = "CONTINUE_DEPLOYMENT"
      }

      terminate_blue_instances_on_deployment_success {
        action                           = "TERMINATE"
        termination_wait_time_in_minutes = 0

      }
    }
  }

  dynamic "blue_green_deployment_config" {
    for_each = var.environment != "prod" ? [] : [1]
    content {
      deployment_ready_option {
        action_on_timeout    = "STOP_DEPLOYMENT"
        wait_time_in_minutes = "60"
      }

      terminate_blue_instances_on_deployment_success {
        action                           = "TERMINATE"
        termination_wait_time_in_minutes = 60

      }
    }
  }




  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.my_resource.name
    service_name = aws_ecs_service.ecs_service.name
  }

  load_balancer_info {
    target_group_pair_info {

      prod_traffic_route {
        listener_arns = [aws_lb_listener.blue.arn]
      }

      test_traffic_route {
        listener_arns = [aws_lb_listener.green.arn]
      }

      target_group {
        name = aws_lb_target_group.blue.name
      }

      target_group {
        name = aws_lb_target_group.green.name
      }
    }
  }
}


# #################################
# # IAM role for ECS - CodeDeploy
# #################################

resource "aws_iam_role" "codedeploy_service_role" {
  name               = join("_", [module.label.id, "codedeploy_service_role"])
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "codedeploy.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

  tags = module.label.tags
}

resource "aws_iam_role_policy_attachment" "ecsCodeDeployServicePolicy" {
  role       = aws_iam_role.codedeploy_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}
