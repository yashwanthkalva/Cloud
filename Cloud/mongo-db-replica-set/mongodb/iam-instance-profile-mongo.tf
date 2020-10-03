#Create IAM Role for Mongo EC2 instance to assume
resource "aws_iam_role" "iam-role-ec2-mongo" {
	name_prefix = "${format("%s-%s-%s-iam-r-mongo-",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME)}"
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

#Poilcy to access route53 zone
resource "aws_iam_role_policy" "iam-role-policy-mongo-route53-access" {
	name = "${format("%s-%s-%s-role-policy-route53-access",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME)}"
	role = "${aws_iam_role.iam-role-ec2-mongo.id}"
	policy = <<EOF
{
  "Version": "2012-10-17",
	"Statement": [
    {
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Effect": "Allow",
      "Resource": [
				"${format("arn:aws:route53:::hostedzone/%s",var.R53_INTERNAL_ZONE_ID)}"
			]
    },
		{
			"Action": [
				"route53:GetChange"
			],
			"Effect": "Allow",
			"Resource": [
				"*"
			]
		},
		{
			"Action": [
				"route53:ListResourceRecordSets"
			],
			"Effect": "Allow",
			"Resource": [
				"*"
			]
		}
  ]
}
EOF
}


#Policy to access EC2 API calls
resource "aws_iam_role_policy" "iam-role-policy-mongo-ec2-describe" {
	name = "${format("%s-%s-%s-role-policy-mongo-ec2-describe",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME)}"
	role = "${aws_iam_role.iam-role-ec2-mongo.id}"
	policy = <<EOF
{
	  "Version": "2012-10-17",
	  "Statement": [
	    {
	      "Action": [
	        "ec2:Describe*"
	      ],
	      "Effect": "Allow",
	      "Resource": "*"
	    }
	  ]
	}
EOF
}


#Create IAM Instance Profile for the mongo EC2 instance
resource "aws_iam_instance_profile" "iam-instance-profile-ec2-mongo" {
	name_prefix  = "${format("%s-%s-%s-iam-ip-mongo-",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME)}"
	role = "${aws_iam_role.iam-role-ec2-mongo.name}"
}
