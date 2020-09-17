resource "aws_vpc" "mongo-vpc-main" {
  cidr_block = "${var.VPC_CIDR}"
}
