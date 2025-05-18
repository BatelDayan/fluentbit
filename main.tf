provider "aws" {
    region = "il-central-1"
}

data "aws_lb_target_group" "existing_tg" {
  name = var.target_group_name
}

data "aws_lb" "existing_alb" {
  name = var.lb_name
}

resource "aws_cloudwatch_log_group" "nginx_logs" {
  name              = "/ecs/fluent-logs"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "nginx_fluentbit" {
  family                   = "nginx-fluentbit"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn
  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = var.container_image
      essential = true
      cpu       = 200
      memoryReservation = 400
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awsfirelens"
        options = {
          Name       = "es"
          Host       = var.elastic_search
          Port       = "443"
          Index      = "nginx"
          suppress_type_name = "true"  # Add this to suppress the _type parameter
          tls        = "on"
        }
      }
    },
    {
      name      = "log-router"
      image     = "amazon/aws-for-fluent-bit:latest"
      essential = true
      cpu       = 50
      memoryReservation = 50
      firelensConfiguration = {
        type = "fluentbit"
        options = {
          "enable-ecs-log-metadata" = "true"
          "config-file-type"        = "file"
          "config-file-value"       = "/fluent-bit/configs/parse-json.conf"
        }
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.nginx_logs.name
          "awslogs-region"        = "il-central-1"
          "awslogs-stream-prefix" = "firelens"
        }
      }
    }
  ])
  tags = {
    Name = "nginx-fluentbit-task"
  }
}

# ECS Service
resource "aws_ecs_service" "nginx_service" {
  name            = var.service_name
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.nginx_fluentbit.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }
  
  load_balancer {
    target_group_arn = data.aws_lb_target_group.existing_tg.arn
    container_name   = "nginx"
    container_port   = 80
  }
}

# Outputs (to display relevant information after deployment)
output "ecs_service_name" {
  value = aws_ecs_service.nginx_service.name
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.nginx_fluentbit.arn
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = data.aws_lb.existing_alb.arn
  port              = 101
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = data.aws_lb_target_group.existing_tg.arn
  }
}
