#Create Collectors security Group and add security rules
resource "aws_security_group" "sg-mongo" {
	name_prefix = "${format("%s-%s-%s-sg-mongo-",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME)}"
	description = "${format("%s-%s-%s-mongo Security Group",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME)}"
	vpc_id = "${aws_vpc.vpc.id}"
	tags {
		Name = "${format("%s-%s-%s-sg-mongo",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME)}"
		Project = "${format("%s-share",var.PRODUCT)}"
		Environment = "${var.ENVIRONMENT}"
	}
}

#

#All Egress Traffic
resource "aws_security_group_rule" "mongo-allow-outbound-all-anywhere" {
  type            = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
	cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.sg-mongo.id}"
}

#allow-inbound-22
resource "aws_security_group_rule" "mongo-bastion-allow-inbound-22" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  source_security_group_id = "${aws_security_group.sg-bastion.id}"
  security_group_id = "${aws_security_group.sg-mongo.id}"
	description = "Allow ssh inbound from bastion"
}

#allow inbound all traffic from k8s nodes
resource "aws_security_group_rule" "mongo-allow-node-inbound-all-ports" {
  type            = "ingress"
  from_port       = 0
  to_port         = 0
  protocol        = "all"
  source_security_group_id = "${aws_security_group.sg-node.id}"
  security_group_id = "${aws_security_group.sg-mongo.id}"
	description = "Allow inbound to Mongo from k8s node subnets"
}

#allow inbound all traffic from peer replica members
resource "aws_security_group_rule" "mongo-allow-peer-inbound-all-ports" {
  type            = "ingress"
  from_port       = 0
  to_port         = 0
  protocol        = "all"
  source_security_group_id = "${aws_security_group.sg-mongo.id}"
  security_group_id = "${aws_security_group.sg-mongo.id}"
	description = "Allow inbound to Mongo from k8s node subnets"
}
