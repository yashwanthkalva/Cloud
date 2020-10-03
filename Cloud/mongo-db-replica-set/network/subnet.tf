
#Look up available AZ in the region
data "aws_availability_zones" "azs" {}

resource "aws_subnet" "mongo-subnet-private" {
	count = "${var.PRIVATE_SUBNET_COUNT}"
	vpc_id = "${aws_vpc.mongo-vpc-main.id}"
	#generate x.x.128.0/20,x.x.144.0/20,x.x.160.0/20 from VPC CIDR
	cidr_block = "${cidrsubnet(var.VPC_CIDR, 4, count.index + 8)}"
	availability_zone = "${data.aws_availability_zones.azs.names[count.index]}"
	map_public_ip_on_launch = "false"
	tags {
		Name = "${format("%s-%s-%s-subnet-private-%d",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME,count.index)}"
		Project = "${format("%s-share",var.PRODUCT)}"
		Environment = "${var.ENVIRONMENT}"
		Tier = "mongo-subnet-private"
	}
	depends_on = ["aws_nat_gateway.mongo-natgw","aws_eip_association.eip_assoc_bastion"]
}


resource "aws_subnet" "mongo-subnet-public" {
	count = "${var.PUBLIC_SUBNET_COUNT}"
	/*
	Explicit dependency added
		aws_internet_gateway.igw :
			To ensure there is outbound connectivity via Internet gateway before Ec2
			instance are launched in public subnets.
	*/
	vpc_id = "${aws_vpc.mongo-vpc-main.id}"
	#generate x.x.64.0/20,x.x.80.0/20,x.x.96.0/20 from VPC CIDR
	cidr_block = "${cidrsubnet(var.VPC_CIDR, 4, count.index + 4)}"
	#availability_zone = "${data.aws_availability_zones.azs.names[count.index]}"
	map_public_ip_on_launch = "true"
	tags {
		Name = "${format("%s-%s-%s-subnet-public-%d",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME,count.index)}"
		Project = "${format("%s-share",var.PRODUCT)}"
		Environment = "${var.ENVIRONMENT}"
		Tier = "public"
	}
	depends_on = ["aws_internet_gateway.mongo-igw"]
}
