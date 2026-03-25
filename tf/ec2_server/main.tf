# STEP2: CREATE EC2 USING PEM & SG

resource "aws_key_pair" "my-key" {
  key_name   = var.key_name
  public_key = file("./key.pub") # replace with your key-name
  
}

resource "aws_instance" "my-ec2" {
  ami           = var.ami   
  instance_type = var.instance_type
  key_name       = aws_key_pair.my-key.key_name        
  vpc_security_group_ids = [aws_security_group.my-sg.id]

  user_data = file("install.sh")
  
  root_block_device {
    volume_size = var.volume_size
  }
  
  tags = {
    Name = var.server_name
  }
}

