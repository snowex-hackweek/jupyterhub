resource "aws_instance" "postgres" {
  # https://cloud-images.ubuntu.com/locator/ec2/
  ami                    = "ami-0a62a78cfedc09d76"
  instance_type          = "r5.2xlarge"
  key_name               = "${var.hackweek_name}-postgres"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.postgres.id]

  tags = {
    Name        = "Postgres machine for ${var.hackweek_name} hackweek"
    Hackweek    = var.hackweek_name
  }

  root_block_device {
    volume_size           = 200
    volume_type           = "gp2"
    delete_on_termination = false
  }

}

resource "aws_security_group" "postgres" {
  name        = "${var.hackweek_name}-postgres"
  description = "Allow SSH"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    # Don't leave fully open for long periods of time?
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
