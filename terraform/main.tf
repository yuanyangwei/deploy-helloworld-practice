terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Note: Create this S3 bucket manually in AWS Console first!
  backend "s3" {
    bucket = "yuanyang-terraform-state-2026" 
    key    = "dev/terraform.tfstate"
    region = "ap-southeast-1"
    dynamodb_table = "terraform-state-lock-wei"
  }
}

provider "aws" {
  region = var.aws_region
}

# --- NETWORK DATA ---
data "aws_vpc" "default" { default = true }
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- REGISTRY ---
resource "aws_ecr_repository" "repo" {
  name         = var.project_name
  force_delete = true
}

# --- SECURITY ---
resource "aws_security_group" "ecs_sg" {
  name   = "${var.project_name}-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- COMPUTE (ECS) ---
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu_units
  memory                   = var.memory_units
  execution_role_arn       = aws_iam_role.ecs_exec_role.arn

  container_definitions = jsonencode([{
    name      = "hello-world"
    image     = "${aws_ecr_repository.repo.repository_url}:latest"
    portMappings = [{
      containerPort = var.container_port
      hostPort      = var.container_port
    }],
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/auto-deployment-practice"
        awslogs-region        = "ap-southeast-1"
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_sg.id]
  }
}

# --- PERMISSIONS ---
resource "aws_iam_role" "ecs_exec_role" {
  name = "${var.project_name}-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}