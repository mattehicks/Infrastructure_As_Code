#!/bin/bash

## Author: Matt Hicks 2017
## mattehicks@gmail.com

#####################################################################################
#
#   This script will create AWS EC2 servers and associate them with a VPC
#   It will return instance ID's on the command line
#	::  AWS credentials need to be already setup
#
######################################################################################

AMI_ID="ami-7a85a01a"
VPC_ID="vpc-d51ef4b0"
SUBNET_ID="subnet-cc0b0e8a"
SECURITY_GROUP_ID="sg-756ae512"
keyfile="aws_keyfile.pem"
hostfile="hostfile.txt"

#OHIO
REGION="us-west-2"

ELB_NAME=TDELB1
VPC_NAME=TDVPC1
INSTANCE_COUNT=1

KEY_PAIR="matt_aws_new"

if [ $# -eq 0 ]; then
	read -p "Enter Option:
	[e] CreateEC2
	[l] CreateELB
	[d] Describe Instances
	[t] Terminate Test Instances
	[s] SSH Config
	[h] Help
	[q] Quit
	" option
else
	option=${1}
fi

if [ "${option}" = "q" ]; then
	exit 0
fi



Help(){
	echo "
	This script uses the AWS CLI which requires Python.
	AWS CLI (pyton) must be installed prior to running the script.

	This script will first use the AWS CLI to create EC2 instances, 
	and will configure them with SSH access.
	Then it will install and configure a webserver.
	And finally will configure an Elastic Load Balancer for the new instances.
	"
}



CreateEC2(){

	#CREATE 3 INSTANCES:

	echo "\n\nCreating EC2\n"

	QUERY=$(aws ec2 run-instances --image-id ${AMI_ID} --count 1 --instance-type t2.micro --key-name ${KEY_PAIR} --subnet-id ${SUBNET_ID} \
	--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='${EC2_TAG}'}]' --associate-public-ip-address --output=text --region ${REGION} ) 


	instanceIPS=$(aws ec2 describe-instances --filters Name=tag:Name,Values=${EC2_TAG} --query Reservations[].Instances[].PublicIpAddress --output=text --region ${REGION})

    #DEBUG
    echo $instanceIPS  | sed "s/[ \t]/ \n/g"

    # update hosts file
    rm $hostfile

    echo $instanceIPS  | sed "s/[ \t]/ \n/g" > $hostfile
    echo "Updated the hosts file"


    ClusterSetup

}

CreateELB(){
	echo "Creating ELB"

	# get subnet
	SUBNET_ID=$(aws ec2 describe-instances  \
	--filters Name=tag:Name,Values=${EC2_TAG} \
	--query "Reservations[*].Instances[*].[SubnetId]" \
	--region ${REGION}
	)

	echo "Return SubnetID: ${SUBNET_ID}"

	echo "Creating ELB..."
	aws elb create-load-balancer  \
	--load-balancer-name ${ELB_NAME} \
	--listeners "Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80"  \
	--subnets ${SUBNET_ID} \
	--security-groups ${SECURITY_GROUP_ID} \
	--region ${REGION}

	ClusterSetup
	echo "all done"
#TODO : Register the EC2's with the ELB
}

DescribeTestInstances(){

	read -p "Enter tag to search: (blank for tags list)
	" tag
	EC2_TAG=${tag:-$EC2_TAG}

	#echo "tag: ${EC2_TAG}"

	# --filter does filtering on server-side
	# --query  does filtering on client-side


	if [ -z ${EC2_TAG} ]
		then {
			QUERY="aws ec2 describe-instances --query 'Reservations[*].Instances[*].{ID:InstanceId,TAG:Tags[*].Key,VALUE:Tags[*].Value}' --region ${REGION} --output table "
		}
	else {
		QUERY="aws ec2 describe-instances --query 'Reservations[*].Instances[*].{IP:PublicIpAddress,ID:InstanceId,TAG:Tags[*].Key,VALUE:Tags[*].Value}' --region ${REGION} --output=table"
		}
	fi

	echo "Executing: 
	${QUERY}

	"

	eval $QUERY

}

TerminateTestInstances(){
	targets=$(aws ec2 describe-instances --filters Name=tag:Name,Values=${EC2_TAG} --query Reservations[*].Instances[*].InstanceId --region ${REGION} --output=text)
	aws ec2 terminate-instances --instance-ids $targets
}


ClusterSetup(){
	echo ""
    #install PSSH Parallel command line tools
    if ! type pssh >/dev/null 2>&1; then
    	echo "installing pip & pssh..."
    	sudo apt-get update
    	sudo apt-get install python-pip -y
    	sudo pip install pssh && sudo pip install pscp
    fi

    if ! [ -e ~/.ssh/id_rsa ]; then
    	ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
    fi
    echo "found id_rsa."
    echo "copying public keys to remote hosts"

    while IFS= read -r host; do
    	echo "\nHost: " $host
        #ssh-copy-id -i ~/.ssh/id_rsa.pub "$host"
        ssh -i ${keyfile}  ubuntu@${host} -o StrictHostKeyChecking=no
        cat ~/.ssh/id_rsa.pub | ssh ubuntu@${host} -i ${keyfile} 'cat >> .ssh/authorized_keys && echo "Key copied"'
        #todo: add error handling
    done < $hostfile

    #pssh : parallel ssh commands (multiple machines)
    echo "\n Testing communication with the cluster..."
    pssh -h $hostfile -l ubuntu -i "date && uname"

    #prsync -h $hostfile -l ubuntu
    echo "Cluster setup done."

}

WebserverCheck(){

	# restart apache
	# each server check its webserver and return the status
	echo "Enabling site in Apache..."
	pssh -h $hostfile -l ubuntu -i "a2ensite $site_url"

	echo "Restarting Apache..."
	echo `/etc/init.d/apache2 restart`

}

InstallWebserver_Nginx(){
	pssh pssh -h $hostfile -l ubuntu -i "a2ensite $site_url"
	echo "Installing Nginx on remote host"

}


InstallWebserver_Apache(){
	HOST=""
	pssh -h cluster -l ec2-user -A -i "df -hT"
	pssh ubuntu@hostname:
	echo "Installing Apache on ${HOST}"
}


GithubCheck()
{
#send SSH key
exit 0;
#on remote server

}


CheckKeys(){
	echo "check for ssh keys.."
    #read key file?
    #while IFS= read -r host; do
    #    ssh-copy-id -i ~/.ssh/id_rsa.pub "$host"
    #done < hostnames_file
    #while IFS= read -r host;do
    #    ssh "$host" 'sudo apt-get install puppet' # also, modify puppet.conf
    #    end < hostnames_file"
}





case ${option} in
	-e | e ) CreateEC2;;
-l | l ) CreateELB;;
-d | d ) DescribeTestInstances;;
-t | t ) TerminateTestInstances;;
-a | a ) InstallWebserver_Apache;;
-n | n ) InstallWebserver_Nginx;;
-c | c ) CheckKeys;;
-s | s ) ClusterSetup;;
-h | h ) Help;;
-q | q )  exit 0;;
esac



exit;
















