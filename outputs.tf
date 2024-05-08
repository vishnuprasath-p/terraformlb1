output "ec2_public_ip" {
   value = [
    aws_instance.myapp-server[0].public_ip,
    aws_instance.myapp-server[1].public_ip
  ]
}