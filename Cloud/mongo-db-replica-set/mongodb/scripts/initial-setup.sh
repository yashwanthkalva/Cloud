#!/bin/bash
PROGNAME=$(basename $0)
exec > >(tee -a -i /var/log/$PROGNAME-$(date +'20%y-%m-%d-%H%M').log)
exec 2>&1
#Script start time
scriptStartTime=`date +%s`
echo "---------------------------------"
echo "$PROGNAME Script "
echo "started at $(date)"
echo "---------------------------------"
#sleep 5
#Variable declaration
##Terraform Variable assignment
instanceId="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
dockerCEVersion="${DOCKER_CE_VERSION}"
ENVIRONMENT="${ENVIRONMENT}"
MONGO_KEYFILE_AND_DATA_DIR="${MONGO_KEYFILE_AND_DATA_DIR}"
region="${AWS_REGION}"


function funInitialSetup() {
	echo "---------------------------------"
	echo "Running $${FUNCNAME[0]}"
	echo "---------------------------------"
  #statements
  #upgrade all of your CentOS system software
  # yum update -y
  #intall useful packages
	#Install epel packages repo
	yum install epel-release -y
	#install jq
	yum install zip unzip wget -y
	yum install jq -y
	jq --version
	yum install htop fping -y
	#Install bind utils
	yum install bind-utils -y

	#install AWS CLI and boto3
  python --version
  yum install python-pip -y
  pip -V
  pip install boto3
  python -c 'import boto3' #Verify
  pip install awscli
  aws --version || funErrorExit "AWS Cli Install failed"
}



#Function set hostName as instance private dns
function funSetHostNameVar() {
	echo "---------------------------------"
	echo "Running $${FUNCNAME[0]}"
	echo "---------------------------------"
	#get the instance PrivateDNS Name, as test requires this
	#Refer https://docs.google.com/document/d/17d4qinC_HnIwrK0GHnRlD1FKkTNdN__VO4TH9-EzbIY/edit#
	hostName=$(aws ec2 describe-instances \
		--instance-ids $instanceId \
		--region $region \
		--query 'Reservations[0].Instances[0].NetworkInterfaces[0].PrivateIpAddresses[0].[PrivateDnsName]' \
		--output text)
}

#Function Set Hostname
function funSetHostName() {
  echo "---------------------------------"
	echo "Running $${FUNCNAME[0]}"
	echo "---------------------------------"
	funSetHostNameVar
  hostnamectl set-hostname --static $hostName && \
  echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg && \
  #Reload the profile to update the HOSTNAME variable
  source /etc/profile || funErrorExit "Setting hostname failed"
	echo "Static hostname set to: " "$(hostname)"
}



function funInstallDocker() {
	echo "---------------------------------"
	echo "Running $${FUNCNAME[0]}"
	echo "---------------------------------"
  yum install -y yum-utils \
    device-mapper-persistent-data \
    lvm2
  yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
	yum install -y \
	  docker-ce-$${dockerCEVersion}
  systemctl enable docker && systemctl start docker

}




function funMountDockerVol() {
	echo "---------------------------------"
	echo "Running $${FUNCNAME[0]}"
	echo "---------------------------------"
	dockerVoldiskName="/dev/xvdg"
	# check if disk exist
	lsblk $dockerVoldiskName || \
	  funErrorExit "$${FUNCNAME[0]}: $dockerVoldiskName disk not found"
	pvcreate $dockerVoldiskName
	vgcreate vg_dockervol $dockerVoldiskName
	lvcreate -n lv_dockervol -l 95%FREE vg_dockervol
	mkfs -t xfs -f /dev/mapper/vg_dockervol-lv_dockervol
	if [[ $? -ne 0 ]]; then
		funErrorExit "$${FUNCNAME[0]}: Unable to create XFS on /dev/mapper/vg_dockervol-lv_dockervol"
	else
		mkdir /var/lib/docker
		echo "/dev/mapper/vg_dockervol-lv_dockervol /var/lib/docker xfs defaults 0 0" >> /etc/fstab
		mount /var/lib/docker || \
			funErrorExit "$${FUNCNAME[0]}: /var/lib/docker mount failed"
	fi
}

function funMountMongoDataVol() {
	echo "---------------------------------"
	echo "Running $${FUNCNAME[0]}"
	echo "---------------------------------"
	diskName="/dev/xvdf"
	# check if disk exist
	lsblk $diskName || \
		funErrorExit "$${FUNCNAME[0]}: $diskName disk not found"
	pvcreate $diskName && \
	vgcreate vg_mongo_datadir $diskName && \
	lvcreate -n lv_mongo_datadir -l 95%FREE vg_mongo_datadir && \
	mkfs -t xfs -f /dev/mapper/vg_mongo_datadir-lv_mongo_datadir
	if [[ $? -ne 0 ]]; then
		funErrorExit "$${FUNCNAME[0]}: Unable to create XFS on /dev/mapper/vg_mongo_datadir-lv_mongo_datadir"
	else
		mkdir -p $MONGO_KEYFILE_AND_DATA_DIR
		echo "/dev/mapper/vg_mongo_datadir-lv_mongo_datadir /test/mongo/datadir xfs defaults 0 0" >> /etc/fstab
		mount $MONGO_KEYFILE_AND_DATA_DIR || \
			funErrorExit "$${FUNCNAME[0]}: /test/mongo/datadir mount failed"
	fi
	systemctl restart docker
	pip install docker-compose
}



#function  funInitiateReplicaSet(){
#		if [[ $CURRENT_MEMBER_COUNT -e ($TOTAL_MEMBERS_COUNT-1) ]]; then
#		fi
#}

function funInstallGePrivateDNSNames() {
	echo "---------------------------------"
	echo "Running $${FUNCNAME[0]}"
	echo "---------------------------------"
	#get the instance PrivateDNS Name, as test requires this
	#Refer https://docs.google.com/document/d/17d4qinC_HnIwrK0GHnRlD1FKkTNdN__VO4TH9-EzbIY/edit#
	privateDNShostNames=$(aws ec2 describe-instances \
		--query 'Reservations[0].Instances[0].NetworkInterfaces[0].PrivateIpAddresses[0].[PrivateDnsName]' \
		--instance-ids $instanceId \
		--region $region \
		--filters 'Name=tag:Type,Values=Mongo' \
		--output text)
		echo "Mongo DB members DNS Names : $privateDNShostNames"
}


funInitialSetup
funSetHostName
funInstallDocker
funMountDockerVol
funMountMongoDataVol
#funInstallGePrivateDNSNames
#funInitiateReplicaSet
#Script End time
scriptEndTime=`date +%s`
echo "---------------------------------"
echo "completed successfully"
echo "script runtime: $((scriptEndTime-scriptStartTime))s "
echo "---------------------------------"
