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
ENVIRONMENT="${ENVIRONMENT}"
MONGO_REPLICA_KEYFILE_NAME=${MONGO_REPLICA_KEYFILE_NAME}
MONGO_KEYFILE_AND_DATA_DIR="${MONGO_KEYFILE_AND_DATA_DIR}"
region="${AWS_REGION}"
INTERNAL_DOMAIN_NAME="${INTERNAL_DOMAIN_NAME}"
MONGO_SUBDOMAIN_NAMES="${MONGO_SUBDOMAIN_NAMES}"
TOTAL_MEMBERS_COUNT="${TOTAL_MEMBERS_COUNT}"
CURRENT_MEMBER_COUNT="${CURRENT_MEMBER_COUNT}"
MONGO_ROOT_USER_PASSWORD="${MONGO_ROOT_USER_PASSWORD}"
MONGO_ADMIN_USER_PASSWORD="${MONGO_ADMIN_USER_PASSWORD}"
MONGO_DBOPS_USER_PASSWORD="${MONGO_DBOPS_USER_PASSWORD}"
MONGO_CLIENT_USER_PASSWORD="${MONGO_CLIENT_USER_PASSWORD}"


# not used any more
function funInstallMongo() {
	 dockerNetworkName="test-docker-network"
	 mongoReplicaSetName="test-replica-set"
	 defaultReplicaKeyFilePath="/data/db/$MONGO_REPLICA_KEYFILE_NAME"
	 docker network create \
	         $dockerNetworkName
	 docker create \
				-p 27017:27017 \
				--name test-mongo-container \
				--net $dockerNetworkName \
				-v $MONGO_KEYFILE_AND_DATA_DIR:/data/db mongo mongod --replSet $mongoReplicaSetName --keyFile $defaultReplicaKeyFilePath
  docker start test-mongo-container
	echo "Mongo members internal R53 DNS Names ------- $INTERNAL_DOMAIN_NAME $MONGO_SUBDOMAIN_NAMES"

}


function funInitiateReplicaSet() {
	#initiate replica set only once from the instance created at last.
 	echo "creating rsinitiate.js file..."
	echo "printing internal domain names $INTERNAL_DOMAIN_NAME"
	echo "printing sub domain names $MONGO_SUBDOMAIN_NAMES"

    if [[ $CURRENT_MEMBER_COUNT -eq $TOTAL_MEMBERS_COUNT ]]; then
   	   echo "creating rsinitiate.js file..."
	   echo "printing internal domain names $INTERNAL_DOMAIN_NAME"
	   echo "printing sub domain names $MONGO_SUBDOMAIN_NAMES"
	   declare -a array
       IFS=' ' read -r -a array <<< "$MONGO_SUBDOMAIN_NAMES"
	   echo "printing array $$array"
	   memberOne="$${array[0]}.$INTERNAL_DOMAIN_NAME"
	   memberTwo="$${array[1]}.$INTERNAL_DOMAIN_NAME"
	   memberThree="$${array[2]}.$INTERNAL_DOMAIN_NAME"
	   echo "rs.initiate(
	        {
	         _id : \"test-replica-set\",
	         members: [{\"_id\" : 0,\"host\" : \"$memberOne:27017\"},{\"_id\" : 1,\"host\" : \"$memberTwo:27017\"},{\"_id\" : 2,\"host\" : \"$memberThree:27017\"}]
	        }
	   )" >> rsinitiate.js

	   echo "rsinitiate.js file created"

	   cp ./rsinitiate.js $MONGO_KEYFILE_AND_DATA_DIR
	   echo "copied javascript file rsinitiate.js to $MONGO_KEYFILE_AND_DATA_DIR"

	   echo "executing docker command..."
	   docker exec -it  test-mongo-container bash -c "mongo localhost:27017/admin < /data/db/rsinitiate.js"
       echo "..done"
	   #Sleep for 30 seconds so that replica set gets created
       sleep 30s
 fi
}

function funCreateDocStoreUsers() {
 #create users only once from the instance created at last once.
 if [[ $CURRENT_MEMBER_COUNT -eq $TOTAL_MEMBERS_COUNT ]]; then

	echo "creating users.js file..."

	echo "db.createUser({
	    user: 'root',
	    pwd: '$MONGO_ROOT_USER_PASSWORD',
	    roles: ['root']
	})

	db.auth('root','$MONGO_ROOT_USER_PASSWORD')

	db.createUser({
	    user: 'admin',
	    pwd: '$MONGO_ADMIN_USER_PASSWORD',
	    roles: [ { role: 'userAdminAnyDatabase', db: 'admin' } ]
	})
	db.createUser({
	    user: 'dbOps',
	    pwd: '$MONGO_DBOPS_USER_PASSWORD',
	    roles: [{ role: 'readWrite', db: 'edi'}]
	})

	db.createUser({
	    user: 'client',
	    pwd: '$MONGO_CLIENT_USER_PASSWORD',
	    roles: [{ role: 'read', db: 'edi'}]
	})
	">> users.js

	echo "users.js file created"
	cp ./users.js $MONGO_KEYFILE_AND_DATA_DIR
	echo "copied javascript file users.js to $MONGO_KEYFILE_AND_DATA_DIR"

	echo "executing docker command..."
	sudo docker exec -it  test-mongo-container bash -c "mongo localhost:27017/admin < /data/db/users.js"
	echo "...done"

 fi

}
#funInstallMongo

funInitiateReplicaSet
funCreateDocStoreUsers

#Script End time
scriptEndTime=`date +%s`
echo "---------------------------------"
echo "completed successfully"
echo "script runtime: $((scriptEndTime-scriptStartTime))s "
echo "---------------------------------"
