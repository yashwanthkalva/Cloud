#Create a NAT gateway
resource "aws_nat_gateway" "mongo-natgw" {
	allocation_id = "${aws_eip.mongo-eip-natgw.id}"
	subnet_id     = "${aws_subnet.mongo-subnet-public.id}"
	#dependency on Internet Gateway
	depends_on = ["aws_internet_gateway.mongo-igw"]
}
