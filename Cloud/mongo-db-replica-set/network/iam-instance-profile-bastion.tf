#Create IAM Role for bastion EC2 instance to assume
resource "aws_iam_role" "iam-role-ec2-bastion" {
	name = "${format("%s-%s-%s-iam-r-bastion-",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME)}"
	assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

#Create IAM Instance Profile for the bastion EC2 instance
resource "aws_iam_instance_profile" "iam-instance-profile-ec2-bastion" {
	name_prefix  = "${format("%s-%s-%s-iam-ip-bastion-",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME)}"
	role = "${aws_iam_role.iam-role-ec2-bastion.name}"
}
