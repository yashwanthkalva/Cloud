#Scripts to deploy to init and  Mongo DB replica set
data "template_file" "shell-script-deploy-initial-setup" {
	count = "${var.MONGO_EC2_COUNT}"
	template = "${file("${path.module}/scripts/initial-setup.sh")}"
	vars {
    DOCKER_CE_VERSION = "${var.DEPLOY_VERSION["dockerCE"]}"
		ENVIRONMENT="${var.ENVIRONMENT}"
		MONGO_KEYFILE_AND_DATA_DIR="${var.MONGO_KEYFILE_AND_DATA_DIR}"
		AWS_REGION="${var.AWS_REGION}"
	}
}

data "template_file" "shell-script-mongo-replica-users-setup" {
	count = "${var.MONGO_EC2_COUNT}"
	template = "${file("${path.module}/scripts/mongo-replica-setup.sh")}"
	vars {
		#The last EC2 instance will be used to create the MongoDB replica set and test docstore users.
		#MONGO_MEMBER_NAME="${(count.index + 1) < var.MONGO_EC2_COUNT ? format("mongo-secondary-%02d",count.index + 1) : format("mongo-primary-%02d",count.index + 1)}"
		TOTAL_MEMBERS_COUNT="${var.MONGO_EC2_COUNT}"
		CURRENT_MEMBER_COUNT="${count.index + 1}"
		ENVIRONMENT="${var.ENVIRONMENT}"
		MONGO_ROOT_USER_PASSWORD="${var.MONGO_ROOT_USER_PASSWORD}"
		MONGO_ADMIN_USER_PASSWORD="${var.MONGO_ADMIN_USER_PASSWORD}"
		MONGO_DBOPS_USER_PASSWORD="${var.MONGO_DBOPS_USER_PASSWORD}"
		MONGO_CLIENT_USER_PASSWORD="${var.MONGO_CLIENT_USER_PASSWORD}"
		MONGO_KEYFILE_AND_DATA_DIR="${var.MONGO_KEYFILE_AND_DATA_DIR}"
		MONGO_REPLICA_KEYFILE_NAME="${var.MONGO_REPLICA_KEYFILE_NAME}"
		AWS_REGION="${var.AWS_REGION}"
		INTERNAL_DOMAIN_NAME="${var.INTERNAL_DOMAIN_NAME}"
		MONGO_SUBDOMAIN_NAMES="${join(" ", var.MONGO_SUBDOMAIN_NAMES)}"
	}
}


#Deploy a EC2 Instance for Mongo DB Server
resource "aws_instance" "ec2-mongo" {
	count = "${var.MONGO_EC2_COUNT}"
	ami = "${var.MONGO_AMI_ID}"
	instance_type = "${var.EC2_INSTANCE_TYPE_MONGO[format("mongo.%s",var.ENVIRONMENT)]}" #Instance type based on environment
	key_name = "${aws_key_pair.ec2-keypair-mongo.key_name}"
	iam_instance_profile = "${aws_iam_instance_profile.iam-instance-profile-ec2-mongo.name}"
	volume_tags {
		Name = "${format("%s-%s-%s-test-mongo-%02d",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME,count.index + 1)}"
		Project = "${format("%s-share",var.PRODUCT)}"
		Environment = "${var.ENVIRONMENT}"
	}
	root_block_device {
		volume_type = "gp2"
		volume_size = "${var.MONGO_EC2_EBS_SIZE[format("mongo.root.%s",var.ENVIRONMENT)]}" #Instance EBS size based on environment
	}

	ebs_block_device {
		device_name = "/dev/xvdf"
		volume_type = "gp2"
		volume_size = "${var.MONGO_EC2_EBS_SIZE[format("mongo.data-dir-vol.%s",var.ENVIRONMENT)]}"
		encrypted = true
	}
	ebs_block_device {
		device_name = "/dev/xvdg"
		volume_type = "gp2"
		volume_size = "${var.MONGO_EC2_EBS_SIZE[format("mongo.docker-vol.%s",var.ENVIRONMENT)]}"
		encrypted = true
	}
	network_interface {
		device_index = 0
		network_interface_id = "${element(var.MONGO_ENI_ID, count.index)}"
	}

	tags {
		Name = "${format("%s-%s-%s-docstore-mongo-%02d",var.PRODUCT,var.ENVIRONMENT,var.REGION_SHORT_NAME,count.index + 1)}"
		Project = "${format("%s-share",var.PRODUCT)}"
		Environment = "${var.ENVIRONMENT}"
	  Type = "Mongo"
	}

	#Used for file and remote-exec provisioner
	connection {
		type     = "ssh"
		user     = "${var.PROVISIONER_CONNECTION_SSH_USER}"
		timeout  = "200s"
		private_key = "${file("${path.root}/.secrets/ec2-key.pem")}"
		bastion_host = "${element(var.BASTION_PUBLIC_IP, 0)}"
	}

	provisioner "file" {
	content     = "${data.template_file.shell-script-deploy-initial-setup.*.rendered[count.index]}"
	destination = "/tmp/terraform-deployment.sh"
	}
	#Execute deployment script
	provisioner "remote-exec" {
		inline = [
			"chmod +x /tmp/terraform-deployment.sh",
			"sudo /tmp/terraform-deployment.sh",
		]
	}
	# Provisioners to run during deploy
	provisioner "file" {
	source      = "${path.root}/.secrets/${var.MONGO_REPLICA_KEYFILE_NAME}"
	destination = "/tmp/${var.MONGO_REPLICA_KEYFILE_NAME}"
	}


	#Execute deployment script
	provisioner "remote-exec" {
		inline = [
			"chmod +x /tmp/${var.MONGO_REPLICA_KEYFILE_NAME}",
			"sudo mv /tmp/${var.MONGO_REPLICA_KEYFILE_NAME} ${var.MONGO_KEYFILE_AND_DATA_DIR}/${var.MONGO_REPLICA_KEYFILE_NAME}",
			"sudo chmod 400 ${var.MONGO_KEYFILE_AND_DATA_DIR}/${var.MONGO_REPLICA_KEYFILE_NAME}"
		]
	}

	provisioner "file" {
	source      = "${path.module}/scripts/docker-compose.yml"
	destination = "/tmp/docker-compose.yml"
	}

	provisioner "remote-exec" {
		inline = [
			"sudo mv /tmp/docker-compose.yml ${var.MONGO_KEYFILE_AND_DATA_DIR}/docker-compose.yml",
			"chmod +x ${var.MONGO_KEYFILE_AND_DATA_DIR}/docker-compose.yml",
			"cd ${var.MONGO_KEYFILE_AND_DATA_DIR}/",
	        "sudo MONGO_KEYFILE_AND_DATA_DIR=${var.MONGO_KEYFILE_AND_DATA_DIR} MONGO_REPLICA_KEYFILE_NAME=${var.MONGO_REPLICA_KEYFILE_NAME} docker-compose up -d"
		]
	}

	provisioner "file" {
	content     = "${data.template_file.shell-script-mongo-replica-users-setup.*.rendered[count.index]}"
	destination = "/tmp/mongo-replica-setup.sh"
	}
	#Execute deployment script
	provisioner "remote-exec" {
		inline = [
			"chmod +x /tmp/mongo-replica-setup.sh",
			"sudo /tmp/mongo-replica-setup.sh",
		]
	}

#Resource lifecycle
	lifecycle {
		ignore_changes = ["subnet_id","user_data","ami","network_interface"]
	}
}
