#Load Balancer Security Group
resource "aws_security_group" "alb" {
  name        = join("_", [module.label.id, "alb"])
  description = "Securoity group for  Application Load Balancer"
  vpc_id      = aws_vpc.my_resource.id

  ingress {
    description = "Blue"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Green"
    from_port   = 88
    to_port     = 88
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = module.label.tags

}

#ECS Task Security Group
resource "aws_security_group" "task_definition" {
  name        = join("_", [module.label.id, "task_definition"])
  description = "Security group for ECS Task definition"
  vpc_id      = aws_vpc.my_resource.id

  ingress {
    description = "Simple Application Port"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = module.label.tags

}
