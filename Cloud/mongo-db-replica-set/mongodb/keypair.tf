#upload the key pair
resource "aws_key_pair" "ec2-keypair-mongo" {
	key_name = "${format("%s-%s-%s-ec2-keypair-mongo",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME)}"
	public_key = "${file("${path.root}/.secrets/ec2-key.pem.pub")}"
}
