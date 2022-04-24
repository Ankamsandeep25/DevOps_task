### Configure AWS Connection###

provider "aws" {
	region = "ap-south-1"
}

###Get the Availability zones in current region###

data "aws_availability_zones" "all" {}

###Creating a Security Group which controls Traffic flow###

resource "aws_security_group" "elb"
	name = "sandeep-example-elb"
	
	# Allow all outbound
	egress {
		from_port 	= 0
		to_port 	= 0
		protocol 	= "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}	
	

	# Inbound HTTP from anywhere
	ingress {
		from_port 	= var.elb_port
		to_port 	= var.elb_port
		protocol 	= "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

### Creating Security group for EC2 Machine in the ASG

resource "aws_security_group" "node" {
	name = "sandeep-example-node"
	
	#Inbound HTTP from anywhere
	ingress {
		from_port 	= var.server_port
		to_port 	= var.server_port
		protocol 	= "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

### Creating an applcation to route traffic across ASG

resource "aws_elb" "loadbalancer" {
	name 					= "sandeep-loadbalancer-example"
	security_groups			= [aws_security_group.elb.id]
	availability_zones		= data.aws_availability_zones.all.names	
	
	health_check {
		target					= "HTTP:${var.server_port}/"
		interval				= 30
		timeout					= 3
		healthy_threshold		= 2
		unhealthy_threshold		= 2
	}
	
	# this is listener for incoming traffic
	listener {
		lb_port 	   	  = var.elb_port
		lb_protocol 	  = "http"
		instance_port	  = var.server_port
		instance_protocol = "http"
	}
}

###create a Launch Config for EC2 instance

resource "aws_launch_configuration" "instance" {
	name = "sandeep-example-launchconfig"
	## Ubuntu server 18.04
	image_id 	= "ami-08ee6644906ff4d6c"
	instance_type = "t2.micro"
	security_groups = [aws_security_group.node.id]
}

###Creating the ASG 

resource "aws_autoscaling_group" "ASG1" {
	name = "sandeep-example-asg"
	launch_configuration = aws_launch_configuration.instance.id
	availability_zones  = data.aws_availability_zones.all.names
	
	min_size = 2
	max_size = 10
	
	load_balancers 		= [aws_elb.loadbalancer.name]
	health_check_type = "ELB"
	
	tag {
	key 	= "Name"
	value 	= "Sandeep-ASG-Task"
	propagate_at_launch = true
	}
}	
