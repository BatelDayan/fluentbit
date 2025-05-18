// ECS Task Definition with Fluent Bit - Lower Resources
resource "aws_ecs_task_definition" "nginx_fluentbit" {
  family                   = "nginx-fluentbit"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  // Reduced CPU to 256 (.25 vCPU)
  cpu                      = "256"
  // Reduced memory to 512 MB
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "nginx:latest"
      essential = true
      // Nginx container gets most of the resources
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
          Host       = "your-elasticsearch-domain.us-east-1.es.amazonaws.com"
          Port       = "443"
          Index      = "nginx"
          Type       = "nginx_logs"
          tls        = "on"
          tls_verify = "on"
        }
      }
    },
    {
      name      = "log-router"
      image     = "amazon/aws-for-fluent-bit:latest"
      essential = true
      // Fluent Bit is very lightweight
      cpu       = 50
      memoryReservation = 50
      firelensConfiguration = {
        type = "fluentbit"
        options = {
          "enable-ecs-log-metadata" = "true"
        }
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.nginx_logs.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "firelens"
        }
      }
    }
  ])

  tags = {
    Name = "nginx-fluentbit-task"
  }
}
