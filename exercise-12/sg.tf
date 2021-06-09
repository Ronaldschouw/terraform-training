# The security group for windows EC2 instances
resource "aws_security_group" "windows" {
  name        = "windows"
  description = "Allow RDP access"
  vpc_id      = "vpc-05e10a7e52ac405bb"

  # Allow port 3389 (RDP)
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow port 5985 (WinRM)
  ingress {
    from_port   = 5985
    to_port     = 5985
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

output "windows_security_group_id" {
  value = "${base64encode(aws_security_group.windows.id)}"
}
