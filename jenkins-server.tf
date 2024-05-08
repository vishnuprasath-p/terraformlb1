data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    
    values = ["hvm"]
  }
}

resource "aws_instance" "myapp-server" {
  count                       = 2
  ami                         = data.aws_ami.latest-amazon-linux-image.id
  instance_type               = var.instance_type
  key_name                    = "0505ec2-key"
  subnet_id                   = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids      = [aws_default_security_group.default-sg.id]
  availability_zone           = var.avail_zone1
  associate_public_ip_address = true
  #user_data                   = file("jenkins-server-script.sh")
  
  tags = {
    Name = "${var.env_prefix}-server-${count.index + 1}"  # No need for count.index in tag
  }
}

# Create the Application Load Balancer
resource "aws_lb" "myapp_lb" {
  name               = "${var.env_prefix}-myapp-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.myapp-subnet-1.id, aws_subnet.myapp-subnet-2.id]
}

# Create the target group for the load balancer
resource "aws_lb_target_group" "myapp_tg" {
  name        = "${var.env_prefix}-myapp-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.myapp-vpc.id
  target_type = "instance"
}

# Create the listener for the load balancer
resource "aws_lb_listener" "myapp_listener" {
  load_balancer_arn = aws_lb.myapp_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myapp_tg.arn
  }
}

# Attach the EC2 instances to the target group
resource "aws_lb_target_group_attachment" "myapp_tg_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.myapp_tg.arn
  target_id        = aws_instance.myapp-server[count.index].id
  port             = 80
}
resource "aws_security_group" "lb_sg" {
  name        = "${var.env_prefix}-lb-sg"
  description = "Allow inbound traffic to the load balancer"
  vpc_id      = aws_vpc.myapp-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

