
#Create Elastic IP for the NAT gateway
resource "aws_eip" "mongo-eip-natgw" {
	vpc = "true"
}
