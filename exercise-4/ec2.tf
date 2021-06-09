resource "aws_instance" "linux" {
  ami           = "ami-0105a535c5aae4a38"
  instance_type = "t2.medium"

  # Associating the security group and making sure the instance is started in the correct subnet.
  vpc_security_group_ids = [aws_security_group.linux.id]
  subnet_id              = "subnet-0bbd7612bccf4f563"

  tags {
    Name = "Gerrit Tamboer"
  }
}

output "linux_public_ip" {
  value = aws_instance.linux.public_ip
}

output "linux_instance_id" {
  value = aws_instance.linux.id
}
