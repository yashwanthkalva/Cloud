#Configure AWS PRovider
provider "aws"{
	version = "~> 1.14"
	access_key = "${var.AWS_ACCESS_KEY}"
	secret_key = "${var.AWS_SECRET_KEY}"
	region = "${var.AWS_REGION}"
}
