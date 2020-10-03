module "mongo"{
	source = "./mongo"
	AWS_REGION = "${var.AWS_REGION}"
	REGION_SHORT_NAME = "${var.REGION_SHORT_NAME[format("%s",var.AWS_REGION)]}"
	ENVIRONMENT = "${var.ENVIRONMENT}"
	PRODUCT = "${var.PRODUCT}"
	VPC_CIDR = "${var.VPC_CIDR}"
  MONGO_AMI_ID = "${data.aws_ami.ami-centos7.image_id}"
	PRIVATE_SUBNET_COUNT="${var.PRIVATE_SUBNET_COUNT}"
	PROVISIONER_CONNECTION_SSH_USER = "${var.PROVISIONER_CONNECTION_SSH_USER}"
	SG_MONGO_ID="${module.network.out-sg-mongo_id}"
	SUB_MONGO_PRIVATE_IDS=["${module.network.out-mongo-ec2-subnet-private_ids}"]
	EC2_INSTANCE_TYPE_MONGO="${var.EC2_INSTANCE_TYPE_MONGO}"
	MONGO_EC2_COUNT="${var.MONGO_EC2_COUNT}"
	INTERNAL_DOCKER_REGISTRY ="${var.INTERNAL_DOCKER_REGISTRY}"
	MONGO_EC2_EBS_SIZE="${var.MONGO_EC2_EBS_SIZE}"
	DEPLOY_VERSION ="${var.DEPLOY_VERSION}"
	BASTION_PUBLIC_IP = ["${module.network.out-bastion-public-ip}"]
}
