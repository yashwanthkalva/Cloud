
#Create Elastic IP for Bastion
resource "aws_eip" "eip-bastion" {
	count = "${var.BASTION_COUNT}"
	vpc = "true"
}

data "template_file" "shell-script-deploy-bastion" {
	count = "${var.BASTION_COUNT}"
	template = "${file("${path.module}/scripts/bastion-deployment.sh")}"
	vars {
		HOST_NAME = "${format("%s-%s-%s-bastion-%02d",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME,count.index + 1)}"
	}
}

#Deploy a EC2 Instance for bastion Server
resource "aws_instance" "ec2-bastion" {
	count = "${var.BASTION_COUNT}"
	ami = "${var.BASTION_AMI_ID}"
	instance_type = "${var.EC2_INSTANCE_TYPE_BASTION[format("bastion.%s",var.ENVIRONMENT)]}" #Instance type based on environment
	key_name = "ess-dev-ec2-key"
	vpc_security_group_ids = ["${aws_security_group.sg-bastion.id}"]
	subnet_id = "${element(aws_subnet.mongo-subnet-public.*.id, 0)}"
	iam_instance_profile = "${aws_iam_instance_profile.iam-instance-profile-ec2-bastion.name}"
	volume_tags {
		Name = "${format("%s-%s-%s-bastion-%02d",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME,count.index + 1)}"
		Project = "${format("%s-share",var.PRODUCT)}"
		Environment = "${var.ENVIRONMENT}"
	}
	root_block_device {
		volume_type = "gp2"
		volume_size = "${var.EC2_EBS_SIZE_BASTION[format("bastion.root.%s",var.ENVIRONMENT)]}" #Instance EBS size based on environment
	}
	tags {
		Name = "${format("%s-%s-%s-bastion-%02d",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME,count.index + 1)}"
		Project = "${format("%s-share",var.PRODUCT)}"
		Environment = "${var.ENVIRONMENT}"
	}
	#Used for file and remote-exec provisioner
	connection {
		type     = "ssh"
		user     = "${var.PROVISIONER_CONNECTION_SSH_USER}"
		timeout  = "200s"
		private_key = "${file("${path.root}/ess-dev-ec2-key.pem")}"
	}

	# copy deploy script
	provisioner "file" {
	content     = "${data.template_file.shell-script-deploy-bastion.*.rendered[count.index]}"
	destination = "/tmp/terraform-deployment.sh"
	}
	#Execute deployment script
	provisioner "remote-exec" {
		inline = [
			"chmod +x /tmp/terraform-deployment.sh",
			"sudo /tmp/terraform-deployment.sh",
		]
	}

#Lifecycle
	lifecycle {
		ignore_changes = ["subnet_id","user_data","ami","network_interface"]
	}
}

#Associate the EIP with Bastion Ec2
resource "aws_eip_association" "eip_assoc_bastion" {
	count = "${var.BASTION_COUNT}"
	instance_id   = "${aws_instance.ec2-bastion.*.id[count.index]}"
	allocation_id = "${aws_eip.eip-bastion.*.id[count.index]}"
}
