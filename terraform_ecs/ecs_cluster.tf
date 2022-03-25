resource "aws_ecs_cluster" "my_resource" {
  name = module.label.id

  configuration {
    execute_command_configuration {
      logging    = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_cluster.name
      }
    }
  }

  tags = module.label.tags

}