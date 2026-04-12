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
  name_prefix = "ec2_sg1"
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
  # 1. Update system and install Docker
  yum update -y
  yum install -y docker git
  systemctl start docker
  systemctl enable docker

  # 2. Install Docker Compose plugin
  mkdir -p /usr/local/lib/docker/cli-plugins/
  curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
  chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

  # 3. Clone the project
  mkdir -p /app
  cd /app
  git clone https://github.com/Akanksha24999/devops-assignment.git .

  # 4. Start the application using Docker Compose
  # We use the plugin syntax 'docker compose'
  docker compose up -d --build
EOF
)
}

# Auto Scaling Group
resource "aws_autoscaling_group" "sgp" {
  desired_capacity          = 2
  max_size                  = 4
  min_size                  = 2
  vpc_zone_identifier       = data.aws_subnets.default.ids

launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

   target_group_arns = [aws_lb_target_group.tgp.arn]

   tag {
      key                 = "Name"
      value               = "App-Instance"
      propagate_at_launch = true
   }

lifecycle {
  create_before_destroy = true
}

}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
   name                 = "scale_up"
   scaling_adjustment    = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.sgp.name
}

resource "aws_autoscaling_policy" "scale_down" {
   name                 = "scale_down"
   scaling_adjustment    = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.sgp.name
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