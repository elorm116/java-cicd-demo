# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create VPC and Subnets
resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}
resource "aws_subnet" "myapp-subnet" {
  vpc_id            = aws_vpc.myapp-vpc.id
  cidr_block        = var.subnet_cidr
  availability_zone = var.availability_zone
  tags = {
    Name = "${var.env_prefix}-subnet"
  }
}

# Create Route Table and Internet Gateway
/*resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id

  route {
    cidr_block = var.route_cidr
    gateway_id = aws_internet_gateway.myapp-igw.id
  }

  tags = {
    Name = "${var.env_prefix}-route-table"
  }
}*/

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id

  tags = {
    Name = "${var.env_prefix}-igw"
  }
}
# Create SSH Key Pair
/*resource "aws_key_pair" "ssh-key" {
  key_name   = "server_key"
  public_key = file(var.key_location)
}*/

# Create Default Route Table with Route
resource "aws_default_route_table" "myapp-default-route-table" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

  route {
    cidr_block = var.route_cidr
    gateway_id = aws_internet_gateway.myapp-igw.id
  }

  tags = {
    Name = "${var.env_prefix}-default-route-table"
  }
  
}

resource "aws_default_security_group" "default-sg" {
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.route_cidr] #Best practice is to limit the number of IP ranges that can access your resources.
  }
    ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.route_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.route_cidr] 
  }

  tags = {
    Name = "${var.env_prefix}-sg"
  }
}

data "aws_ami" "amazon_linux_image_2023" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}
# Launch EC2 Instance
resource "aws_instance" "myapp-server" {
  ami           = data.aws_ami.amazon_linux_image_2023.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.myapp-subnet.id
  vpc_security_group_ids = [aws_default_security_group.default-sg.id]
  availability_zone = var.availability_zone
  associate_public_ip_address = true
  key_name = "DevOps"

# Commands to run at boot time
  user_data = file("entry-script.sh")

  tags = {
    Name = "${var.env_prefix}-instance"
  }
}

# Associate Route Table with Subnet
/*resource "aws_route_table_association" "myapp-subnet-association" {
  subnet_id      = aws_subnet.myapp-subnet.id
  route_table_id = aws_route_table.myapp-route-table.id
}*/

