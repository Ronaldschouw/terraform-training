# This data source searches for the AMI in AWS, and returns the AMI ID
data "aws_ami" "linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["*terraform-training*"]
  }
}

resource "aws_instance" "linux" {
  ami           = data.aws_ami.linux.id
  instance_type = "t2.medium"

  # Associating the security group and making sure the instance is started in the correct subnet.
  vpc_security_group_ids = [aws_security_group.linux.id]
  subnet_id              = "subnet-01ef24cb191338867"

  tags {
    Name = "Gerrit Tamboer"
  }

  # This provisioner copies the test file to the instance
  provisioner "file" {
    source      = "testfile"
    destination = "/home/fullstaq/testfile"

    connection {
      type     = "ssh"
      user     = "fullstaq"
      password = "training"

      # set to 15m to avoid timeout
      timeout = "15m"
    }
  }
}

output "linux_public_ip" {
  value = aws_instance.linux.public_ip
}

output "linux_instance_id" {
  value = aws_instance.linux.id
}
