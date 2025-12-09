resource "aws_eip" "nat" {
  for_each = var.nat_method == "gateway" ? { "nat" = 1 } : {}
  domain   = "vpc"

  tags = {
    Name        = "${var.lambda_function_name}-nat-eip-${var.environment}"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  for_each      = var.nat_method == "gateway" ? { "nat" = 1 } : {}
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name        = "${var.lambda_function_name}-nat-${var.environment}"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}

data "aws_ami" "nat_instance" {
  most_recent = true

  filter {
    name   = "name"
    values = ["fck-nat-al2023-*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  owners = ["568608671756"]
}

resource "aws_security_group" "nat_instance" {
  for_each    = var.nat_method == "instance" ? { "nat" = 1 } : {}
  name_prefix = "nat-instance-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_network_interface" "nat_instance" {
  for_each = var.nat_method == "instance" ? { "nat" = 1 } : {}

  subnet_id       = aws_subnet.public.id
  security_groups = [aws_security_group.nat_instance[each.key].id]

  source_dest_check = false
}

resource "aws_instance" "nat_instance" {
  for_each      = var.nat_method == "instance" ? { "nat" = 1 } : {}
  ami           = data.aws_ami.nat_instance.id
  instance_type = "t4g.nano"

  network_interface {
    network_interface_id = aws_network_interface.nat_instance[each.key].id
    device_index         = 0
  }

  tags = {
    Name = "nat-instance-${var.environment}"
  }
}
