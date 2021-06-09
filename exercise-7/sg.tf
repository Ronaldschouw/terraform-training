# The security group for linux EC2 instances
resource "aws_security_group" "linux" {
  name        = "linux"
  description = "Allow SSH access"
  vpc_id      = "vpc-05e10a7e52ac405bb"

  # Allow port 22 (SSH)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all egress traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # The name tag with my name
  tags {
    Name = "Gerrit Tamboer"
  }
}

output "linux_security_group_id" {
  value = aws_security_group.linux.id
}
