# WIP

##################################
# Networking: VPC and Subnets
##################################
resource "aws_vpc" "main" {
  # Define the main VPC with a CIDR block for internal IP addressing
  cidr_block = "10.0.0.0/16"
  # Enable DNS support in the VPC for service discovery
  enable_dns_support   = true
  # Enable DNS hostnames for instances launched in this VPC
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"  # Tag for identification
  }
}

resource "aws_internet_gateway" "igw" {
  # Attach an Internet Gateway to the VPC to allow internet access
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"  # Tag for identification
  }
}

resource "aws_subnet" "public_subnet" {
  # Public subnet in the VPC for resources needing internet access
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  # Automatically assign public IPs to instances launched here
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name = "public-subnet"  # Tag for identification
  }
}

resource "aws_subnet" "private_subnet" {
  # Private subnet for internal resources without direct internet access
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "private-subnet"  # Tag for identification
  }
}

resource "aws_route_table" "public_rt" {
  # Route table associated with public subnet to route traffic to internet
  vpc_id = aws_vpc.main.id

  route {
    # Route all outbound traffic to the internet gateway
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"  # Tag for identification
  }
}

resource "aws_route_table_association" "public_assoc" {
  # Associate the public subnet with the public route table
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

##################################
# IAM Role for ECS Task Execution
##################################
resource "aws_iam_role" "ecs_task_exec" {
  # IAM role assumed by ECS tasks to allow them to interact with AWS services
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"  # ECS tasks assume this role
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_policy" {
  # Attach the managed policy that grants ECS task execution permissions
  role       = aws_iam_role.ecs_task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

##################################
# ECS Cluster and Services
##################################
resource "aws_ecs_cluster" "main" {
  # Define the ECS cluster to run containerized services
  name = "main-cluster"
}

resource "aws_ecs_task_definition" "frontend_task" {
  # Task definition for frontend service using Fargate launch type
  family                   = "frontend-task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"   # CPU units allocated
  memory                   = "512"   # Memory in MB allocated
  network_mode             = "awsvpc" # Use VPC networking mode
  execution_role_arn       = aws_iam_role.ecs_task_exec.arn  # Role for ECS task execution

  container_definitions = jsonencode([
    {
      name      = "frontend"  # Container name
      image     = "nginx:alpine"  # Container image to use
      essential = true  # Mark container as essential for the task
      portMappings = [{
        containerPort = 80  # Container port to expose
        protocol      = "tcp"
      }]
    }
  ])
}

resource "aws_ecs_task_definition" "backend_task" {
  # Task definition for backend service using Fargate launch type
  family                   = "backend-task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"   # CPU units allocated
  memory                   = "512"   # Memory in MB allocated
  network_mode             = "awsvpc" # Use VPC networking mode
  execution_role_arn       = aws_iam_role.ecs_task_exec.arn  # Role for ECS task execution

  container_definitions = jsonencode([
    {
      name      = "backend"  # Container name
      image     = "kennethreitz/httpbin"  # Container image to use
      essential = true  # Mark container as essential for the task
      portMappings = [{
        containerPort = 80  # Container port to expose
        protocol      = "tcp"
      }]
    }
  ])
}

resource "aws_ecs_service" "frontend" {
  # ECS service to run frontend tasks on Fargate
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend_task.arn
  desired_count   = 1  # Number of task instances to run
  launch_type     = "FARGATE"

  network_configuration {
    # Use private subnet for network isolation
    subnets         = [aws_subnet.private_subnet.id]
    assign_public_ip = false  # Do not assign public IPs
    security_groups  = []     # No specific security groups attached
  }

  load_balancer {
    # Associate the service with the frontend target group for load balancing
    target_group_arn = aws_lb_target_group.frontend_tg.arn
    container_name   = "frontend"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http]  # Ensure ALB listener is created first
}

resource "aws_ecs_service" "backend" {
  # ECS service to run backend tasks on Fargate
  name            = "backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend_task.arn
  desired_count   = 1  # Number of task instances to run
  launch_type     = "FARGATE"

  network_configuration {
    # Use private subnet for network isolation
    subnets         = [aws_subnet.private_subnet.id]
    assign_public_ip = false  # Do not assign public IPs
    security_groups  = []     # No specific security groups attached
  }

  load_balancer {
    # Associate the service with the backend target group for load balancing
    target_group_arn = aws_lb_target_group.backend_tg.arn
    container_name   = "backend"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http]  # Ensure ALB listener is created first
}

##################################
# ALB, Target Groups, Listener
##################################
resource "aws_lb" "app_alb" {
  # Application Load Balancer to distribute traffic to ECS services
  name               = "app-alb"
  internal           = false  # Internet-facing ALB
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_subnet.id]  # ALB in public subnet

  tags = {
    Name = "app-alb"  # Tag for identification
  }
}

resource "aws_lb_target_group" "frontend_tg" {
  # Target group to route requests to frontend ECS tasks
  name     = "frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    # Health check configuration to monitor targets
    path                = "/"  # Health check path
    interval            = 30   # Interval between health checks in seconds
    timeout             = 5    # Timeout for each health check
    healthy_threshold   = 2    # Number of successes before healthy
    unhealthy_threshold = 2    # Number of failures before unhealthy
  }
}

resource "aws_lb_target_group" "backend_tg" {
  # Target group to route requests to backend ECS tasks
  name     = "backend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    # Health check configuration to monitor targets
    path                = "/"  # Health check path
    interval            = 30   # Interval between health checks in seconds
    timeout             = 5    # Timeout for each health check
    healthy_threshold   = 2    # Number of successes before healthy
    unhealthy_threshold = 2    # Number of failures before unhealthy
  }
}

resource "aws_lb_listener" "http" {
  # Listener for HTTP traffic on port 80 for the ALB
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    # Default action to return 404 for unmatched requests
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404 not found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "frontend_rule" {
  # Listener rule to forward root path requests to frontend target group
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_lb_listener_rule" "backend_rule" {
  # Listener rule to forward /api/* requests to backend target group
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

##################################
# WAF Attached to ALB
##################################
resource "aws_wafv2_web_acl" "alb_waf" {
  # Web Application Firewall to protect ALB from common threats
  name        = "alb-waf"
  scope       = "REGIONAL"  # Regional scope for ALB
  description = "WAF for ALB"
  default_action {
    allow {}  # Allow requests by default unless blocked by rules
  }

  visibility_config {
    cloudwatch_metrics_enabled = true  # Enable metrics for monitoring
    metric_name                = "alb-waf"
    sampled_requests_enabled   = true  # Enable sampling of requests
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action {
      none {}  # No override, use managed rule action
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"  # AWS managed rule group
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "common-rule-set"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_wafv2_web_acl_association" "waf_alb_assoc" {
  # Associate the WAF ACL with the ALB to enforce rules
  resource_arn = aws_lb.app_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.alb_waf.arn
}

###############################################################
# Full AWS Infrastructure: VPC, ECS (Fargate), ALB, WAF, CDN, #
# S3-hosted Static Frontend and API Backend via CloudFront    #
###############################################################

resource "aws_cloudfront_origin_access_identity" "oai" {
  # OAI allows CloudFront to access private S3 content securely
  comment = "OAI for accessing S3 content"
}

resource "aws_s3_bucket" "html_bucket" {
  # S3 bucket to store static HTML content served via CloudFront
  bucket = "my-static-html-cdn-bucket"

  tags = {
    Name = "HTMLBucket"
  }
}

resource "aws_s3_object" "index_html" {
  # Upload the local HTML file to S3 with public read access
  bucket       = aws_s3_bucket.html_bucket.id
  key          = "index.html"
  source       = "${path.module}/index.html"
  content_type = "text/html"
  acl          = "public-read"
}

# Upload additional HTML files with dummy content to S3
resource "aws_s3_object" "about_html" {
  bucket  = aws_s3_bucket.html_bucket.id
  key     = "about.html"
  content = "<html><body><h1>About Page</h1><p>This is a sample about page.</p></body></html>"
  content_type = "text/html"
  acl     = "public-read"
}

resource "aws_s3_object" "contact_html" {
  bucket  = aws_s3_bucket.html_bucket.id
  key     = "contact.html"
  content = "<html><body><h1>Contact Page</h1><p>This is a sample contact page.</p></body></html>"
  content_type = "text/html"
  acl     = "public-read"
}

resource "aws_s3_object" "blog_html" {
  bucket  = aws_s3_bucket.html_bucket.id
  key     = "blog.html"
  content = "<html><body><h1>Blog Page</h1><p>This is a sample blog page.</p></body></html>"
  content_type = "text/html"
  acl     = "public-read"
}

resource "aws_cloudfront_distribution" "cdn" {
  # Enable the CloudFront distribution
  enabled             = true

  # Default object served if viewer doesn’t specify file
  default_root_object = "index.html"

  # Define origin as S3 bucket where static HTML is hosted
  origin {
    domain_name = aws_s3_bucket.html_bucket.bucket_regional_domain_name
    origin_id   = "s3-origin"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  # Caching and request behavior config
  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"  # Enforce HTTPS
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    compress = true  # GZIP compression
  }

  # Allow global access
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Use default SSL cert (for non-custom domains)
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "SimpleCDN"
  }
}