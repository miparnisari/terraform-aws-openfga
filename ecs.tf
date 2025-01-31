resource "aws_security_group" "ecs_task" {
  name   = "${local.name}-task-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    protocol        = "tcp"
    from_port       = var.port
    to_port         = var.port
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_ecs_cluster" "this" {
  name = local.name
  tags = local.tags
}

resource "aws_ecs_task_definition" "run" {
  family                   = "run"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name        = local.name
      image       = var.openfga_container_image
      command     = ["run"]
      networkMode = "awsvpc"
      essential   = true
      portMappings = [
        {
          containerPort = var.port
          hostPort      = var.port
        }
      ],
      environment = [
        {
          name  = "OPENFGA_PLAYGROUND_ENABLED"
          value = "false"
        },
        {
          name  = "OPENFGA_LOG_FORMAT"
          value = "json"
        },
        {
          name  = "OPENFGA_DATASTORE_ENGINE"
          value = var.db_type
        },
        {
          name  = "OPENFGA_DATASTORE_URI"
          value = local.db_conn_string
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.id
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      },
    }
  ])

  tags = local.tags
}

resource "aws_ecs_service" "run" {
  name                = "${local.name}-run"
  cluster             = aws_ecs_cluster.this.id
  task_definition     = aws_ecs_task_definition.run.arn
  launch_type         = "FARGATE"
  scheduling_strategy = "REPLICA"
  desired_count       = var.service_count

  network_configuration {
    subnets          = aws_subnet.public[*].id
    assign_public_ip = true # needed to pull from docker hub
    security_groups  = [aws_security_group.ecs_task.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = local.name
    container_port   = var.port
  }

  depends_on = [
    aws_lb_listener.this,
    aws_rds_cluster_instance.this,
    aws_iam_role.ecs_task_execution_role,
  ]

  tags = local.tags
}

resource "aws_ecs_task_definition" "migrate" {
  count = (var.db_migrate && var.db_type == "postgres") ? 1 : 0

  family                   = "migrate"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name        = "${local.name}-migrate"
      image       = var.openfga_container_image
      command     = ["migrate"]
      networkMode = "awsvpc"
      essential   = true
      environment = [
        {
          name  = "OPENFGA_DATASTORE_ENGINE"
          value = var.db_type
        },
        {
          name  = "OPENFGA_DATASTORE_URI"
          value = local.db_conn_string
        }
      ],
    }
  ])

  tags = local.tags
}

# tflint-ignore: terraform_unused_declarations
# comment out if using in-memory storage
data "aws_ecs_task_execution" "run_migrate" {
  desired_count   = (var.db_migrate && var.db_type == "postgres") ? 1 : 0

  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.migrate[0].id
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_task.id]
    assign_public_ip = true # needed to pull from docker hub
  }
}