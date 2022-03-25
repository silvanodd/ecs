resource "aws_ecs_service" "ecs_service" {
  name            = module.label.id
  cluster         = aws_ecs_cluster.my_resource.id
  task_definition = aws_ecs_task_definition.my_resource.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    security_groups  = [aws_security_group.task_definition.id]
    subnets          = [for subnet in aws_subnet.my_resource : subnet.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = join("_", [module.label.id, "container"])
    container_port   = 8000
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

}
