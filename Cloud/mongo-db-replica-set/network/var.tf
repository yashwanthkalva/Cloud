variable "AWS_REGION" {}

variable "REGION_SHORT_NAME" {}

variable "ENVIRONMENT" {}

variable "PRODUCT" {}

variable "VPC_CIDR" {
}
variable "PUBLIC_SUBNET_COUNT" {}

variable "PRIVATE_SUBNET_COUNT" {}
variable "BASTION_COUNT" {}
#Instance type based on environement
variable "EC2_INSTANCE_TYPE_BASTION" {
  type = "map"
}
variable "BASTION_AMI_ID" {}

#Instance EBS Vol Size based on environement
variable "EC2_EBS_SIZE_BASTION" {
  type = "map"
}

variable "TRUSTED_INCOMING_CIDR" {
	type = "list"
}

#Provisioner Connections ssh user
variable "PROVISIONER_CONNECTION_SSH_USER" {
  default = "centos"
}
