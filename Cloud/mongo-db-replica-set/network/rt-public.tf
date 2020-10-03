#Create a Public Route table
resource "aws_route_table" "rt-public" {
	vpc_id = "${aws_vpc.mongo-vpc-main.id}"
	tags {
		Name = "${format("%s-%s-%s-rt-public",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME)}"
		Project = "${format("%s-share",var.PRODUCT)}"
		Environment = "${var.ENVIRONMENT}"
	}
}

resource "aws_route" "rt-public-route" {
	route_table_id = "${aws_route_table.rt-public.id}"
	destination_cidr_block = "0.0.0.0/0"
	gateway_id = "${aws_internet_gateway.mongo-igw.id}"
}

#Associate public Route Table to public Subnets
resource "aws_route_table_association" "rt-sub-public" {
	count = "${var.PUBLIC_SUBNET_COUNT}"
	subnet_id      = "${aws_subnet.mongo-subnet-public.*.id[count.index]}"
	route_table_id = "${aws_route_table.rt-public.id}"
}
