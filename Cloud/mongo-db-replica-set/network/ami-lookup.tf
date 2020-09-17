#Fetch the AMI for CentOS 7 (x86_64)
#Refer the link, https://aws.amazon.com/marketplace/fulfillment?productId=b7ee8a69-ee97-4a49-9e68-afaee216db2e&ref=cns_srchrow , for the AMI information.
#Refer link, https://wiki.centos.org/Cloud/AWS for CentOS 7 Image information.
data "aws_ami" "ami-centos7" {
	most_recent = true
	owners = ["aws-marketplace"]
	filter {
		name = "description"
		values = ["CentOS Linux 7 x86_64 HVM EBS*"]
	}

	filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

	filter {
    name = "product-code"
    values = ["aw0evgkw8e5c1q413zgy5pjce"]
  }
}
