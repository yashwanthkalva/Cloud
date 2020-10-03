
#Create Bastion Server security Group and add security rules
resource "aws_security_group" "sg-bastion" {
	name_prefix = "${format("%s-%s-%s-sg-bastion-",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME)}"
	description = "${format("%s-%s-%s-bastion Security Group",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME)}"
	vpc_id = "${aws_vpc.mongo-vpc-main.id}"
	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = "${var.TRUSTED_INCOMING_CIDR}"
	}
	tags {
		Name = "${format("%s-%s-%s-sg-bastion",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME)}"
		Project = "${format("%s-share",var.PRODUCT)}"
		Environment = "${var.ENVIRONMENT}"
	}
}

#Note: for bastion SG use the aws_security_group to add the rules to make sure the accepted
#is always maintained
