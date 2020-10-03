#Create internet gateway
resource "aws_internet_gateway" "mongo-igw" {
	vpc_id = "${aws_vpc.mongo-vpc-main.id}"
	tags {
		Name = "${format("%s-%s-%s-mongo-igw",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME)}"
		Project = "${format("%s-share",var.PRODUCT)}"
		Environment = "${var.ENVIRONMENT}"
	}
}
