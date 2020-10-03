#Create a private Route table
resource "aws_route_table" "rt-private" {
	vpc_id = "${aws_vpc.mongo-vpc-main.id}"
	tags {
		Name = "${format("%s-%s-%s-rt-private",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME)}"
		Project = "${format("%s-share",var.PRODUCT)}"
		Environment = "${var.ENVIRONMENT}"
	}
}

resource "aws_route" "rt-private-route" {
	route_table_id = "${aws_route_table.rt-private.id}"
	destination_cidr_block = "0.0.0.0/0"
	nat_gateway_id = "${aws_nat_gateway.mongo-natgw.id}"
}

#Associate Private Route Table to Private Subnets
resource "aws_route_table_association" "rt-sub-private" {
	count = "${var.PRIVATE_SUBNET_COUNT}"
	subnet_id      = "${aws_subnet.mongo-subnet-private.*.id[count.index]}"
	route_table_id = "${aws_route_table.rt-private.id}"
}
