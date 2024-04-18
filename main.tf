provider "aws" {
    region = "us-east-1"
}

# 1. Create vpc
resource "aws_vpc" "prod-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "production"
    }
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.prod-vpc.id
}

# 3. Create Custom Route Table
resource "aws_route_table" "prod-route-table" {
    vpc_id = aws_vpc.prod-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    }
    route {
        ipv6_cidr_block = "::/0"
        gateway_id = aws_internet_gateway.gw.id
    }
    tags = {
        Name = "Prod"
    }
}

variable "subnet_prefix" {
  #type        = string
  #default     = "10.0.1.0/24"
  description = "CIDR block for the subnet"
}


# 4. Create a Subnet
resource "aws_subnet" "prod-subnet-1" {
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block = var.subnet_prefix[0].cidr_block
    availability_zone = "us-east-1a"
    tags = {
        Name = var.subnet_prefix[0].name
    }
}

resource "aws_subnet" "prod-subnet-2" {
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block = var.subnet_prefix[1].cidr_block
    availability_zone = "us-east-1a"
    tags = {
        Name = var.subnet_prefix[1].name
    }
}

# 5. Associate Subnet to Route Table
resource "aws_route_table_association" "a" {
    subnet_id = aws_subnet.prod-subnet-1.id
    route_table_id = aws_route_table.prod-route-table.id
}

# 6. Create a Security Group to allow SSH(22), HTTP(80), HTTPS(443)
resource "aws_security_group" "allow_web" {
    name = "allow_web_traffic"
    description = "Allow Web inbound traffic"
    vpc_id = aws_vpc.prod-vpc.id
    ingress {
        # Allows TCP traffic on port 443, just this port 
        description = "HTTPS"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] #what subnets can reach this
    }
    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    # Allows all traffic outbound. 
    # -1 for protocol means any protocol
    # CIDR block - all the IP addresses
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "security-group-ssh-http-s"
    }
}

# 7. Create a network interface with an ip in the subnet that was created in step 4
resource "aws_network_interface" "web-server-nic" {
    subnet_id = aws_subnet.prod-subnet-1.id
    private_ips = ["10.0.1.50"]
    security_groups = [aws_security_group.allow_web.id]
}

# 8. Assign an elastic IP to the network interface created in step 7
resource "aws_eip" "one" {
    vpc                       = true
    network_interface         = aws_network_interface.web-server-nic.id
    associate_with_private_ip = "10.0.1.50"
    depends_on                = [aws_internet_gateway.gw] #to have a public ip an igw is needed
} 

# 9. Create Ubuntu Server and install/enable Apache2
resource "aws_instance" "web-server" {
    ami = "ami-080e1f13689e07408"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "main-key"
    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.web-server-nic.id
    }
    # telling terraform that on deployment of this server -> run few commands
    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                EOF
    tags = {
        Name = "web-server-ubuntu"
    }
}

# getting the output value
output "public_ip" {
    value = aws_eip.one.public_ip
    description = "The public IP address of the main server"
}

output "instance_id" {
    value = aws_instance.web-server.id
    description = "The instance ID of the main server"
}

output "server_private_id" {
    value = aws_network_interface.web-server-nic.private_ip
}