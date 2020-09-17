#!/bin/bash

#Variable declaration
PROGNAME=$(basename $0)

#Script start time
scriptStartTime=`date +%s`
echo "---------------------------------"
echo "$PROGNAME Script "
echo "started at $(date)"
echo "---------------------------------"

# Variables read from init.conf
productName=""
envType=""
AWSRegion=""

initConfPath="./init.conf"
secretsPath="./.secrets"
mkdir -p $secretsPath
keyPairEC2="$secretsPath/ec2-key.pem"
templateTerraformVariableFile="./TEMPLATE-variable.sed"
templateTerraformTrustedIncomingCIDRFile="./TEMPLATE-trusted-incoming-cidr.sed"
autoGenTerraformVariableFile="./AUTOGEN-variable.tf"
autoGenTerraformTrustedIncomingCIDRFile="./AUTOGEN-trusted-incoming-cidr.tf"
genTerraformVarFile="./terraform.tfvars"
mongoReplicaKeyFileName="mongoReplicaKeyFile"

#Error handling function
function funErrorExit() {
	echo
	echo "ERROR: ${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	#Script End time
	scriptEndTime=`date +%s`
	echo "---------------------------------"
	echo "completed with error"
	echo "script runtime: $((scriptEndTime-scriptStartTime))s "
	echo "---------------------------------"
	exit 1
}

#Input validation
function funCheckInputEmpty() {
  local localVarName=$1
  local localInput=$2
  if [[ -z $localInput ]]; then
    echo "input '$localVarName' ${FUNCNAME[0]}:fail"
    funErrorExit "input '$localVarName' ${FUNCNAME[0]}:Fail"
  else
    echo "input '$localVarName' ${FUNCNAME[0]}:Pass"
  fi
}

function funCheckLengthOfInput() {
	local localVarName=$1
  local localInput=$2
  local localDesiredLen=$3
  local localCheck=${#localInput}
  if [[ $localCheck -lt $localDesiredLen ]]; then
    echo "input '$localVarName' ${FUNCNAME[0]}:Pass"
  else
		echo "input '$localVarName' ${FUNCNAME[0]}:fail"
		funErrorExit "input '$localVarName' ${FUNCNAME[0]}:Fail"
  fi
}

function funCheckEnvTypeAcceptedValue() {
	local localVarName=$1
  local localInput=$2
  case $localInput in
    dev )
      echo "input '$localVarName' ${FUNCNAME[0]}:Pass"
      ;;
    prod )
      echo "input '$localVarName' ${FUNCNAME[0]}:Pass"
      ;;
    * )
			echo "input '$localVarName' ${FUNCNAME[0]}:fail"
			funErrorExit "input '$localVarName' ${FUNCNAME[0]}:Fail"
      ;;
  esac
}


function funLoadInitConf() {
	echo "---------------------------------"
  echo "Running ${FUNCNAME[0]}"
  echo "---------------------------------"
	if [[ -f $initConfPath ]]; then
		source $initConfPath
	else
		funErrorExit "$${FUNCNAME[0]}: file $initConfPath not found"
	fi
}

function funInitConfValaidation() {
	echo "---------------------------------"
  echo "Running ${FUNCNAME[0]}"
  echo "---------------------------------"
	# Load init.conf
	funLoadInitConf
	# check variable productName
	funCheckInputEmpty "productName" $productName
	funCheckLengthOfInput "productName" $productName 8
	# check variable envType
	funCheckInputEmpty "envType" $envType
	funCheckEnvTypeAcceptedValue "envType" $envType
	# check variable AWSRegion
	funCheckInputEmpty "AWSRegion" $AWSRegion
}

function funGenSSHKeyPair() {
	echo "---------------------------------"
  echo "Running ${FUNCNAME[0]}"
  echo "---------------------------------"
  local localKeyPairName=$1
  mkdir -p $secretsPath
	if [[ -e "$localKeyPairName" ]]; then
		echo -e "\n$localKeyPairName already exists, skipping... "
	else
		echo -e "Generation new $localKeyPairName"
		ssh-keygen -t rsa -b 2048 -f $localKeyPairName -q -N ""
    chmod 400 $localKeyPairName
	fi
}

function funAutoGenTerraformVarTF() {
	echo "---------------------------------"
	echo "Running ${FUNCNAME[0]}"
	echo "---------------------------------"
	sed -e "s/@@env@@/$envType/" \
	-e "s/@@product@@/$productName/" \
	-e "s/@@aws_region@@/$AWSRegion/" \
	$templateTerraformVariableFile \
	> $autoGenTerraformVariableFile
}

function funAutoGenTerraformTrustedIncomingCIDR() {
	echo "---------------------------------"
  echo "Running ${FUNCNAME[0]}"
  echo "---------------------------------"
	terraformExecMachineExternalIP="$(curl ipinfo.io/ip)/32"
	sed -e "s%@@terraform_exec_machine_external_ip@@%$terraformExecMachineExternalIP%" \
	$templateTerraformTrustedIncomingCIDRFile \
	> $autoGenTerraformTrustedIncomingCIDRFile
}

function funKubeEncryptionKey() {
  echo "---------------------------------"
  echo "Running ${FUNCNAME[0]}"
  echo "---------------------------------"
	if [[ -e $secretsPath/kube-encryption.key ]]; then
		echo -e "\n$secretsPath/kube-encryption.key already exists, skipping... "
	else
		echo -e "Generation $secretsPath/kube-encryption.key"
		echo $(head -c 32 /dev/urandom | base64) > $secretsPath/kube-encryption.key
	fi
}

function funGenKubeBootstrapTokenKey() {
  echo "---------------------------------"
  echo "Running ${FUNCNAME[0]}"
  echo "---------------------------------"
	if [[ -e $secretsPath/kube-bootstrap-token.key ]]; then
		echo -e "\n$secretsPath/kube-bootstrap-token.key already exists, skipping... "
	else
		echo -e "Generation $secretsPath/kube-bootstrap-token.key"
		echo "$(openssl rand -hex 3).$(openssl rand -hex 8)" > $secretsPath/kube-bootstrap-token.key
	fi
}

function funGenCAAuthTokenKey() {
  echo "---------------------------------"
  echo "Running ${FUNCNAME[0]}"
  echo "---------------------------------"
	if [[ -e $secretsPath/ca-auth-token.key ]]; then
		echo -e "\n$secretsPath/ca-auth-token.key already exists, skipping... "
	else
		echo -e "Generation $secretsPath/ca-auth-token.key"
		echo "$(tr -dc 'A-F0-9' < /dev/urandom | head -c32)" > $secretsPath/ca-auth-token.key
	fi
}

function funGenRDSMasterDBUserPass() {
  echo "---------------------------------"
  echo "Running ${FUNCNAME[0]}"
  echo "---------------------------------"
	if [[ -e $secretsPath/rds-master-user-pass.key ]]; then
		echo -e "\n$secretsPath/rds-master-user-pass.key already exists, skipping... "
	else
		echo -e "Generation $secretsPath/rds-master-user-pass.key"
		echo "$(tr -cd '[:alnum:]' < /dev/urandom | fold -w41 | head -n1)" > $secretsPath/rds-master-user-pass.key
	fi
}


function funGenMongoRootUserPass() {
  echo "---------------------------------"
  echo "Running ${FUNCNAME[0]}"
  echo "---------------------------------"
	if [[ -e $secretsPath/mongo-root-user-pass.key ]]; then
		echo -e "\n$secretsPath/mongo-root-user-pass.key already exists, skipping... "
	else
		echo -e "Generation $secretsPath/mongo-root-user-pass.key"
		echo "$(tr -cd '[:alnum:]' < /dev/urandom | fold -w41 | head -n1)" > $secretsPath/mongo-root-user-pass.key
	fi
}

function funGenMongoAdminUserPass() {
  echo "---------------------------------"
  echo "Running ${FUNCNAME[0]}"
  echo "---------------------------------"
	if [[ -e $secretsPath/mongo-admin-user-pass.key ]]; then
		echo -e "\n$secretsPath/mongo-admin-user-pass.key already exists, skipping... "
	else
		echo -e "Generation $secretsPath/mongo-admin-user-pass.key"
		echo "$(tr -cd '[:alnum:]' < /dev/urandom | fold -w41 | head -n1)" > $secretsPath/mongo-admin-user-pass.key
	fi
}

function funGenMongoDbOpsUserPass() {
  echo "---------------------------------"
  echo "Running ${FUNCNAME[0]}"
  echo "---------------------------------"
	if [[ -e $secretsPath/mongo-dbops-user-pass.key ]]; then
		echo -e "\n$secretsPath/mongo-dbops-user-pass.key already exists, skipping... "
	else
		echo -e "Generation $secretsPath/mongo-dbops-user-pass.key"
		echo "$(tr -cd '[:alnum:]' < /dev/urandom | fold -w41 | head -n1)" > $secretsPath/mongo-dbops-user-pass.key
	fi
}

function funGenMongoClientUserPass() {
  echo "---------------------------------"
  echo "Running ${FUNCNAME[0]}"
  echo "---------------------------------"
	if [[ -e $secretsPath/mongo-client-user-pass.key ]]; then
		echo -e "\n$secretsPath/mongo-client-user-pass.key already exists, skipping... "
	else
		echo -e "Generation $secretsPath/mongo-client-user-pass.key"
		echo "$(tr -cd '[:alnum:]' < /dev/urandom | fold -w41 | head -n1)" > $secretsPath/mongo-client-user-pass.key
	fi
}




function funGenMongoReplicaKeyFile() {
	if [[ -e $secretsPath/mongoReplicaKeyFile ]]; then
		echo -e "\n$secretsPath/$mongoReplicaKeyFileName replica key file already exists, skipping... "
	else
		echo -e "Generating $secretsPath/$mongoReplicaKeyFileName"
		openssl rand -base64 756 > $secretsPath/$mongoReplicaKeyFileName
		chmod 400 $secretsPath/$mongoReplicaKeyFileName
	fi
}



function funGenTerraformVar() {
	echo "---------------------------------"
  echo "Running ${FUNCNAME[0]}"
  echo "---------------------------------"
	funKubeEncryptionKey
	funGenKubeBootstrapTokenKey
	funGenCAAuthTokenKey
	funGenRDSMasterDBUserPass
	funGenMongoRootUserPass
	funGenMongoAdminUserPass
	funGenMongoDbOpsUserPass
	funGenMongoClientUserPass
        funGenMongoReplicaKeyFile
	kubeEncryptionKey="$(cat $secretsPath/kube-encryption.key)"
	KubeBootstrapTokenKey="$(cat $secretsPath/kube-bootstrap-token.key)"
	caAuthTokenKey="$(cat $secretsPath/ca-auth-token.key)"
	RDSMasterDBUserPass="$(cat $secretsPath/rds-master-user-pass.key)"
	MongoRootUserPass="$(cat $secretsPath/mongo-root-user-pass.key)"
	MongoAdminUserPass="$(cat $secretsPath/mongo-admin-user-pass.key)"
	MongoDbOpsUserPass="$(cat $secretsPath/mongo-dbops-user-pass.key)"
	MongoClientUserPass="$(cat $secretsPath/mongo-client-user-pass.key)"
	echo -e "Generation new $genTerraformVarFile"
	cat << _EOF_ > $genTerraformVarFile
AWS_ACCESS_KEY = ""
AWS_SECRET_KEY = ""
KUBERNETES_DISCOVERY_TOKEN = "$KubeBootstrapTokenKey"
KUBERNETES_ENCRYPTION_KEY = "$kubeEncryptionKey"
CA_AUTH_TOKEN_KEY = "$caAuthTokenKey"
RDS_MASTER_USER_PASSWORD = "$RDSMasterDBUserPass"
MONGO_ROOT_USER_PASSWORD = "$MongoRootUserPass"
MONGO_ADMIN_USER_PASSWORD = "$MongoAdminUserPass"
MONGO_DBOPS_USER_PASSWORD = "$MongoDbOpsUserPass"
MONGO_CLIENT_USER_PASSWORD = "$MongoClientUserPass"
MONGO_REPLICA_KEYFILE_NAME = "mongoReplicaKeyFile"
_EOF_
}

funInitConfValaidation
# Generate a New Keypair for Ec2 instances
funGenSSHKeyPair $keyPairEC2
# Generate AUTOGEN-*.tf
funAutoGenTerraformVarTF
funAutoGenTerraformTrustedIncomingCIDR
funGenTerraformVar

echo "------------------------------------------------------"
echo "*********Important***************"
echo "store the below items in a safe place for backup"
echo "	-$secretsPath/ec2-key.pem and ec2-key.pem.pub"
echo "	-$secretsPath/kube-encryption.key"
echo "	-$secretsPath/kube-bootstrap-token.key"
echo "	-$secretsPath/ca-auth-token.key"
echo "	-$secretsPath/rds-master-user-pass.key"
echo "	-$secretsPath/mongo-root-user-pass.key"
echo "	-$secretsPath/mongo-admin-user-pass.key"
echo "	-$secretsPath/mongo-dbops-user-pass.key"
echo "	-$secretsPath/mongoReplicaKeyFile"
echo "------------------------------------------------------"

#Script End time
scriptEndTime=`date +%s`
echo "---------------------------------"
echo "completed successfully"
echo "script runtime: $((scriptEndTime-scriptStartTime))s "
echo "---------------------------------"
