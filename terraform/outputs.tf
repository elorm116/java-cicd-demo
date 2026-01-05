# Print Outputs
output "aws_vpc_id" {
  value = aws_vpc.myapp-vpc.id
}
output "aws_subnet_id" {
  value = aws_subnet.myapp-subnet.id
}
output "aws_ami_id" {
  value = data.aws_ami.amazon_linux_image_2023.id
}
output "aws_instance_public_ip" {
  value = aws_instance.myapp-server.public_ip
}