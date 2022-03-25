resource "aws_cloudwatch_log_group" "ecs_cluster" {
  name = join("_", [module.label.id, "ecsCluster"])
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "ecs_task_definition" {
  name = join("_", [module.label.id, "ecsTask"])
  retention_in_days = 7
}
