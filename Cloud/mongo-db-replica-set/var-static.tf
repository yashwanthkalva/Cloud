variable "AWS_ACCESS_KEY" {}

variable "AWS_SECRET_KEY" {}


variable "PRODUCT" { default = "mongo" }
variable "ENVIRONMENT" { default = "dev" }
variable "AWS_REGION" { default = "us-east-1" }

variable "VPC_CIDR" {
	default = "10.100.0.0/16"
}
variable "PRIVATE_SUBNET_COUNT" {
  default = "3"
}

variable "PUBLIC_SUBNET_COUNT" {
  default = "1"
}

variable "MONGO_EC2_COUNT" {
	default = "3"
}

# All Instance type count
variable "BASTION_COUNT" {
	type = "map"
	default = {
		#bastion
		dev = "1"
		prod = "1"
	}
}

variable "INTERNAL_DOCKER_REGISTRY" {
	description = <<EOF
This map variable controls the internal docker registry.
Accepted value:
	deploy: true or false
	name: <string>
	port: <a valid port number>
Requires :
	INTERNAL_INGRESS.deploy = true
	DEFAULT_STORAGE_CLASS.DEPLOY = true
EOF
	type = "map"
	default = {
		deploy = "true"
		name = "cdr"
		port = "5000"
	}
}


variable "DEPLOY_VERSION" {
	description = <<EOF
This map variable controls the various component versions.
**warning** Changing this requires extensive testing.
EOF
	type = "map"
	default = {
		kubernetes = "1.11.2"
		etcd = "3.3.1"
		dockerCE = "18.06.1.ce-3.el7"
		cfssl = "1.2"
		kube-dns = "1.14.10"
		core-dns = "1.2.0"
		helm = "2.9.1"
		calico-node = "3.0.6"
		calico-cni = "2.0.5"
		calico-kube-controller = "2.0.4"
		nginx-ingress-controller = "0.19.0"
	}
}

#Instance type based on environement
variable "EC2_INSTANCE_TYPE_BASTION" {
  type = "map"
  default = {
		#bastion
		bastion.dev = "t2.micro"
		bastion.prod = "t2.small"
  }
}

#Instance EBS Vol Size based on environement
variable "EC2_EBS_SIZE_BASTION" {
  type = "map"
  default = {
		#bastion
		bastion.root.dev = 10
		bastion.root.prod = 10
  }
}



variable "MONGO_EC2_EBS_SIZE" {
  type = "map"
  default = {
		#mongo
		mongo.root.dev = 25
		mongo.root.prod = 25
		# Disk to Create LVM Thin pool for docker containers to support devicemapper
		mongo.data-dir-vol.dev = 20
		mongo.data-dir-vol.prod = 20
		# Disk to mount /var/lib/docker
		mongo.docker-vol.dev = 15
		mongo.docker-vol.prod = 15
  }

}




variable "TRUSTED_INCOMING_CIDR" {
	type = "list"
	#External IP of the Machine executing this terraform script
	default = ["182.75.203.18/32"]
}


variable "EC2_INSTANCE_TYPE_MONGO" {
	type = "map"
	default = {
		#mongo
		mongo.dev = "m4.large"
		mongo.prod = "m4.large"
	}
}
#Provisioner Connections ssh user
variable "PROVISIONER_CONNECTION_SSH_USER" {
  default = "centos"
}

variable "REGION_SHORT_NAME" {
  type = "map"
  default = {
		# Region short name to add to naming convention
		# Update this list when new AWs region is added
		# https://docs.aws.amazon.com/general/latest/gr/rande.html
		us-east-2 = "use2"
		us-east-1 = "use1"
		us-west-1 = "usw1"
		us-west-2 = "usw2"
		ap-south-1 = "aps1"
		ap-northeast-2 = "apne2"
		ap-northeast-3 = "apne3"
		ap-southeast-1 = "apse1"
		ap-southeast-2 = "apse2"
		ap-northeast-1 = "apne1"
		ca-central-1 = "cac1"
		cn-north-1 = "cnn1"
		eu-central-1 = "euc1"
		eu-west-1 = "euw1"
		eu-west-2 = "euw2"
		eu-west-3 = "euw3"
		sa-east-1 = "sae1"
  }
}
