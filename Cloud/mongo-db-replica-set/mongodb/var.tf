variable "AWS_REGION" {}

variable "REGION_SHORT_NAME" {

}

variable "DEPLOY_VERSION" {

    type = "map"
}

variable "PROVISIONER_CONNECTION_SSH_USER" {}

#should be rnd|preprod|rnd|poc|prod
variable "ENVIRONMENT" {}

variable "PRODUCT" {}

variable "R53_INTERNAL_ZONE_ID" {}

variable "BASTION_PUBLIC_IP" {
  type = "list"
}


variable "SG_MONGO_ID" {}

variable "MONGO_ENI_ID" {

type = "list"
}

variable "MONGO_AMI_ID" {}

variable "EC2_INSTANCE_TYPE_MONGO" {
  type = "map"
}

variable "MONGO_EC2_COUNT" {}



variable "MONGO_EC2_EBS_SIZE" {
  type = "map"
}

variable "MONGO_NODE_SUBNET_IDS" {
  type = "list"
}
variable "MONGO_ROOT_USER_PASSWORD" {}
variable "MONGO_ADMIN_USER_PASSWORD" {}
variable "MONGO_DBOPS_USER_PASSWORD" {}
variable "MONGO_CLIENT_USER_PASSWORD" {}

variable "MONGO_KEYFILE_AND_DATA_DIR" {}

variable "MONGO_REPLICA_KEYFILE_NAME" {}

variable "INTERNAL_DOMAIN_NAME" {}

variable "MONGO_SUBDOMAIN_NAMES" {
  type="list"
}
