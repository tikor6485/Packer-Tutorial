# Retrieve the Packer-generated AMI
data "aws_ami" "packer_image" {
  most_recent = true
  filter {
    name   = "name"
    values = ["Packer-Image-EC2-AWS"]
  }
  owners = ["self"]
}

# Create an EC2 instance for testing
resource "aws_instance" "Tirdad_instance_packer" {
  ami                         = data.aws_ami.packer_image.id
  instance_type               = var.T_instance_type
  subnet_id                   = aws_subnet.Tprivate1.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.Tlb01.id]

  tags = {
    Name = "${var.T_instance_name}Packer01"
  }
}

# ---------------------------------------------------------------------------------

# Create a new VPC
resource "aws_vpc" "Tmyvpc01" {
  cidr_block = var.T_vpc_cidr_block

  tags = {
    Name = "${var.T_env_prefix}VPC01"
  }
}

# Create two subnets in different Availability Zones in the VPC
resource "aws_subnet" "Tprivate1" {
  cidr_block        = var.T_subnet_cidr_block_1
  availability_zone = var.T_avail_zone_1
  vpc_id            = aws_vpc.Tmyvpc01.id

  tags = {
    Name = "${var.T_env_prefix}Subnet01"
  }
}

resource "aws_subnet" "Tprivate2" {
  cidr_block        = var.T_subnet_cidr_block_2
  availability_zone = var.T_avail_zone_2
  vpc_id            = aws_vpc.Tmyvpc01.id

  tags = {
    Name = "${var.T_env_prefix}Subnet02"
  }
}

# Create aws_internet_gateway
resource "aws_internet_gateway" "Tmyigw01" {
  vpc_id = aws_vpc.Tmyvpc01.id

  tags = {
    Name = "${var.T_env_prefix}myigw"
  }
}

# Create aws_route_table
resource "aws_route_table" "Tmyroutetable01" {
  vpc_id = aws_vpc.Tmyvpc01.id

  route {
    cidr_block = var.T_cidr_block
    gateway_id = aws_internet_gateway.Tmyigw01.id
  }

  tags = {
    Name = "${var.T_env_prefix}myroutetable01"
  }
}

# Create a new aws_route_table_association to associate the route table with the subnet within the vpc
resource "aws_route_table_association" "Tmyroutetableassociation01" {
  subnet_id      = aws_subnet.Tprivate1.id
  route_table_id = aws_route_table.Tmyroutetable01.id
}

# ----------------------------------------------------------------------------------

# Create a security group for the load balancer
resource "aws_security_group" "Tlb01" {
  name_prefix = "Tlbssh"
  vpc_id      = aws_vpc.Tmyvpc01.id

  ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TK All teraffic"
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.T_env_prefix}sg"
  }
}

# Allow incoming traffic to the load balancer from any source
resource "aws_security_group_rule" "Tlbingress01" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Tlb01.id
}

# Create an AWS Application Load Balancer with two subnets and a security group
resource "aws_lb" "T_myalb01" {
  name               = "myalb01-unique"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.Tprivate1.id, aws_subnet.Tprivate2.id]
  security_groups    = [aws_security_group.Tlb01.id]

  tags = {
    Name = "${var.T_env_prefix}myalb01"
  }
}

# Create an AWS Target Group for the instances
resource "aws_lb_target_group" "Tmytg01" {
  name_prefix = "mytg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.Tmyvpc01.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/"
    port                = "traffic-port"
  }
}

# Attach an instance to the target group
resource "aws_lb_target_group_attachment" "Tmytgattachment01" {
  target_group_arn = aws_lb_target_group.Tmytg01.arn
  target_id        = aws_instance.Tirdad_instance_packer.id
  port             = "80"
}

# ----------------------------------------------------------------------------------

# Define an EC2 launch template with the specified properties
resource "aws_launch_template" "Tmylaunchtemplate01" {
  name                   = "${var.T_env_prefix}mylaunchtemplate"
  image_id               = data.aws_ami.packer_image.id
  instance_type          = var.T_instance_type
  vpc_security_group_ids = [aws_security_group.Tlb01.id]

  # Set the user data script to start a web server
  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "Hello, World!" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
  )

  # Add a tag to the instance to identify it with a specific name
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.T_env_prefix}myinstancename"
    }
  }

  # Add a block device mapping to specify the root volume size
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 30
    }
  }

  # Set up a network interface to use a specific subnet and security group
  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    subnet_id                   = aws_subnet.Tprivate1.id
    security_groups             = [aws_security_group.Tlb01.id]
  }
}


