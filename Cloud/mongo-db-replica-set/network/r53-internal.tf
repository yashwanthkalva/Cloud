#Create a internal R53 zone
resource "aws_route53_zone" "r53-internal" {
	name = "${format("%s-%s-%s",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME)}"
	vpc {
		vpc_id = "${aws_vpc.vpc.id}"
	}
	comment = "${format("%s-%s-%s",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME)}"
	tags {
		Name = "${format("%s-%s-%s-r53-internal",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME)}"
		Project = "${format("%s-share",var.PRODUCT)}"
		Environment = "${var.ENVIRONMENT}"
	}
}

#Create a DHCP option set with the internal domain name
resource "aws_vpc_dhcp_options" "dhcp-option-internaldns" {
	domain_name = "${format("%s-%s-%s",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME)}"
	domain_name_servers = ["AmazonProvidedDNS"]
	tags {
		Name = "${format("%s-%s-%s-dhcp-option-internaldns",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME)}"
		Project = "${format("%s-share",var.PRODUCT)}"
		Environment = "${var.ENVIRONMENT}"
	}
}

#Associate the DHCP option set to the VPC
resource "aws_vpc_dhcp_options_association" "dns_resolver" {
	vpc_id          = "${aws_vpc.vpc.id}"
	dhcp_options_id = "${aws_vpc_dhcp_options.dhcp-option-internaldns.id}"
}
