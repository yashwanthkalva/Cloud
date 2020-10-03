# Create mongo ENI before the Instance to add the Route53 record
resource "aws_network_interface" "eni-mongo" {
  count = "${var.MONGO_EC2_COUNT}"
  subnet_id       = "${element(aws_subnet.sub-node-private.*.id, count.index)}"
  security_groups = ["${aws_security_group.sg-mongo.id}"]
  #set static IP for mongo nodes (11th ip of the mongo subnets from 3 AZ )
  private_ips = ["${cidrhost(element(aws_subnet.sub-node-private.*.cidr_block, count.index), 12)}"]
  tags {
		Name = "${format("%s-%s-eni-mongo-%02d",var.REGION_SHORT_NAME,var.ENVIRONMENT,count.index + 1)}"
		Project = "${format("%s-share",var.PRODUCT)}"
		Environment = "${var.ENVIRONMENT}"
	}
}

#Create a internal Route 53 A record
resource "aws_route53_record" "r53-record-mongo" {
	count = "${var.MONGO_EC2_COUNT}"
	zone_id = "${aws_route53_zone.r53-internal.zone_id}"
	name    = "${format("%s-%s-%s-docstore-mongo-%02d",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME,count.index + 1)}"
#  name = "${(count.index + 1) < var.MONGO_EC2_COUNT ? format("docstore-mongo-%s-%02d",var.ENVIRONMENT,count.index + 1) : format("docstore-mongo-primary-%s-%02d",var.ENVIRONMENT,count.index + 1)}"
	type    = "A"
	ttl     = "5"
	records = ["${aws_network_interface.eni-mongo.*.private_ips[count.index]}"]
}
