provider "aws" {
    region = "us-east-1"
}

resource "aws_launch_template" "home-temp" {
    name = "home-temp"
    image_id = "ami-0b6c6ebed2801a5cb"
    key_name = "ubuntu"
    vpc_security_group_ids = ["sg-04cd3dac63c3d9587"]
    instance_type = "t3.micro"
    tag_specifications {
      resource_type = "instance"
      tags = {
        Name = "home"
      }
    }
    user_data = base64encode(<<-EOF
            #!/bin/bash
            apt update -y
            apt install nginx -y
            echo "<h1>WELCOME TO HOMEPAGE</h1>" > /var/www/html/index.html
            systemctl start nginx
            systemctl enable nginx
    EOF
    )
}

resource "aws_launch_template" "cloth-temp" {
    name = "cloth-temp"
    image_id = "ami-0b6c6ebed2801a5cb"
    key_name = "ubuntu"
    vpc_security_group_ids = ["sg-04cd3dac63c3d9587"]
    instance_type = "t3.micro"
    tag_specifications {
      resource_type = "instance"
      tags = {
        Name = "cloth"
      }
    }
    user_data = base64encode(<<-EOF
            #!/bin/bash
            apt update -y
            apt install nginx -y
            mkdir -p /var/www/html/cloth
            echo "<h1>WELCOME TO Clothes Section</h1>" > /var/www/html/cloth/index.html
            systemctl start nginx
            systemctl enable nginx
    EOF
    )
}

resource "aws_autoscaling_group" "home-asg" {
    name = "home-asg"
    availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
    desired_capacity = 1
    min_size = 1
    max_size = 3
    health_check_type = "ELB"
    health_check_grace_period = "300"

    launch_template {
      id = aws_launch_template.home-temp.id
      version = "$Latest"
    }

    target_group_arns = [aws_lb_target_group.home-tg.arn]
}

resource "aws_autoscaling_policy" "home_scale_up" {
    name ="home_scale_up"
    autoscaling_group_name = aws_autoscaling_group.home-asg.name
    adjustment_type = "ChangeInCapacity"
    scaling_adjustment = 1
    cooldown = 120
}

resource "aws_cloudwatch_metric_alarm" "home_asg_scale_up" {
    alarm_description = "Monitors cpu utilization"
    alarm_actions = [aws_autoscaling_policy.home_scale_up.arn]
    alarm_name = "home_asg_scale_up"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    namespace = "AWS/EC2"
    metric_name = "CPUUTILIZATION"
    threshold = 70
    evaluation_periods = 2
    period = 120
    statistic = "Average"

    dimensions = {
      AutoScalingGroupName = aws_autoscaling_group.home-asg.name
    }
}

resource "aws_autoscaling_group" "cloth-asg" {
    name = "cloth-asg"
    availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
    desired_capacity = 1
    min_size = 1
    max_size = 3
    health_check_type = "ELB"
    health_check_grace_period = "300"

    launch_template {
      id = aws_launch_template.cloth-temp.id
      version = "$Latest"
    }

    target_group_arns = [aws_lb_target_group.cloth-tg.arn]
}

resource "aws_autoscaling_policy" "cloth_scale_up" {
    name ="cloth_scale_up"
    autoscaling_group_name = aws_autoscaling_group.cloth-asg.name
    adjustment_type = "ChangeInCapacity"
    scaling_adjustment = 1
    cooldown = 120
}

resource "aws_cloudwatch_metric_alarm" "cloth_asg_scale_up" {
    alarm_description = "Monitors cpu utilization"
    alarm_actions = [aws_autoscaling_policy.cloth_scale_up.arn]
    alarm_name = "cloth_asg_scale_up"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    namespace = "AWS/EC2"
    metric_name = "CPUUTILIZATION"
    threshold = 70
    evaluation_periods = 2
    period = 120
    statistic = "Average"

    dimensions = {
      AutoScalingGroupName = aws_autoscaling_group.cloth-asg.name
    }
}

resource "aws_lb_target_group" "home-tg" {
    name = "home-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = "vpc-0784448f97090f55b"
}

resource "aws_lb_target_group" "cloth-tg" {
    name = "cloth-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = "vpc-0784448f97090f55b"
}

resource "aws_lb" "my-alb" {
    name = "my-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = ["sg-04cd3dac63c3d9587"]
    subnets = ["subnet-0838ba36bad6dda16", "subnet-09eb2824f0c2b3d9d", "subnet-09f918c5806636495"]
}

resource "aws_lb_listener" "my_alb_listener" {
    load_balancer_arn = aws_lb.my-alb.arn
    port = 80
    protocol = "HTTP"
    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.home-tg.arn
    }
}

resource "aws_lb_listener_rule" "my_alb_listener_rule" {
    listener_arn = aws_lb_listener.my_alb_listener.arn
    priority = 2
    action {
      type = "forward"
      target_group_arn = aws_lb_target_group.cloth-tg.arn
    }
    condition {
      path_pattern {
        values = ["/cloth*"]
      }
    }
}