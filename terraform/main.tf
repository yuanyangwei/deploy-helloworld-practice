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
    region = var.aws_region
    dynamodb_table = "terraform-state-lock-wei"
  }
}

provider "aws" {
  region = var.aws_region
}

# --- VPC & NETWORK DATA ---
data "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = data.aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}
resource "aws_subnets" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone = "${var.aws_region}a"
  tags = {
    name = "${var.project_name}-public-subnet"
  }
}


resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}
# --- REGISTRY ---
resource "aws_ecr_repository" "repo" {
  name         = var.project_name
  force_delete = true
}

# --- SECURITY ---
resource "aws_security_group" "ecs_sg" {
  name   = "${var.project_name}-sg"
  description = "Allow inbound traffic to ECS task"
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
    subnets          = [aws_subnet.public.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_sg.id]
  }
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
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