provider "aws" {
  region     = var.keys["region"]
  access_key = var.keys["access_key"]
  secret_key = var.keys["secret_key"]
}

data "aws_vpc" "default" {
  
  id      = "vpc-0ce6661916a7908b9"
}

data "aws_subnets" "default" {
   filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


# Security Group for ALB
resource "aws_security_group" "alb_sgp" {
  name        = "alb_sgp"
  vpc_id      = data.aws_vpc.default.id

  # Inbound Rules (Ingress)
 ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Rules (Egress)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for EC2 Instances
resource "aws_security_group" "ec2_sg" {
  name_prefix = "ec2_sg"
  vpc_id      = data.aws_vpc.default.id

  # Inbound Rules (Ingress)
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Outbound Rules (Egress)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch Template for EC2_Instances
resource "aws_launch_template" "example" {
  image_id = "ami-05d2d839d4f73aafb"
  instance_type = "t3.micro"
  key_name = "my-key"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_sg.id]
  }

    user_data = base64encode(<<-EOF
  #!/bin/bash
  # 1. Update and install software
  yum update -y
  yum install -y httpd
  
  # 2. Start the service
  systemctl start httpd
  systemctl enable httpd
  
  # 3. Create a simple home page
   c cd ~/devops-assignment
            git pull origin main
            docker compose down
            docker compose up -d --build

  # 4. Restart Apache to apply changes
    systemctl restart httpd
EOF
)
}

# Application Load balancer
resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sgp.id]
  subnets            = data.aws_subnets.default.ids
}

#Target Group For ALB
resource "aws_lb_target_group" "tgp" {
  name     = "tgp"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    interval            = 20           
    path                = "/"     
    timeout             = 3            
    healthy_threshold   = 2            
    unhealthy_threshold = 2            
    matcher             = "200"         
  }
}

# ALB Listener to forward traffic to the Target Group
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.server_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tgp.arn
  }
}