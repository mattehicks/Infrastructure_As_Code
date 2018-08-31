#!/bin/bash


#todo : 
#install webserver auto setup
#install ELB and SSH auto setup
#install RDS / Mysql setup

hostfile="/home/ec2-user/devops/servers.txt"
devops="sh ~/devops/devops.sh"
syscheck="sh ~/devops/syscheck.sh"

args=("$@")
#echo arguments to the shell
#echo ${args[0]} ${args[1]} ${args[2]}

if [ $# -eq 0 ]; then
	read -p "Enter Option:
	[i] Install       	[t] Test
	[c]	Cluster Setup
	[p] Performance   	[s] System Info
	[m] Memory Info  	[C] CPU Stats
	[n] Network       	[r] Monitor All
	[d] Devops Check    [q] Quit
	" option
else
	option=${1}
fi

if [ "${option}" == "q" ]; then
	exit 0
fi


Help() {
	echo " Purpose is to install utilities and a robust ADMIN WORKSTATION on this machine"
	echo " Additionally; automated status and performance checking of this environment"
	echo " This program will confirm before it will install anything."
	exit 0
}



Install() {
#INstall utilities and a robust ADMIN WORKSTATION on this machine.
#No cluster installation or tools will start yet.
	echo ""
	echo " Purpose is to install utilities and a robust ADMIN WORKSTATION on this machine"
	echo " Additionally; automated status and performance checking of this environment"
	echo " This program will confirm before it will install anything."
	echo " Please run the \"Cluster Setup\" to install additional cluster management tools"
	echo """
	Programs to install:

	Pip & Python
	AWS CLI
	Fabric3
	Github
	Fabric3 - fast provisioning for servers
        Terraform - for scalng and building AWS environments
	OpsWorks modules - for automating code deploys. Uses AWS and gihub integration.
 	Tmux - for custom admin monitor screens in this suite.

 	Tools & Utilities:
 	tmux, htop, systools

	"""

read -p "Are you sure? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
fi


	cd /usr/share
	sudo pip install awscli
	yum install wget
	wget https://bootstrap.pypa.io/get-pip.py

	#check for 'tar'
	#yum install 'tar'


	wget  https://pypi.python.org/packages/bd/f4/3143e0289faf0883228017dbc6387a66d0b468df646645e29e1eb89ea10e/scandir-1.5.tar.gz
  	wget https://pypi.python.org/packages/a4/70/d07a28ea595953acacc128a6efe25696be20b2e1d3e3c81ef4b55410b488/ipython-5.3.0.tar.gz#md5=26c175feb92f1c9033968432a93845ea
  	wget https://bootstrap.pypa.io/get-pip.py

  	tar -xzf scandir-1.5.tar.gz
  	tar -xzf ipython-5.3.0
  	cd ipython-5.3.0
  	python setup.py

  	python install setup.py
  	python setup.py install
  	python get-pip.py
  	export PATH="/usr/local/bin:$PATH"

    #get AWS information
	if ! type aws > /dev/null;  then
		read -p "Install AWS CLI now?  [y]"  awsvar
		if [[ "${awsvar}" == "y" || ""  ]]; then
			sudo pip install awscli -y
		fi
	fi


	#get fabric information
	if ! type fabric3 --version > /dev/null;  then
		read -p "Install FABRIC now?  [y]"  awsvar
		if [[ "${awsvar}" == "y" || ""  ]]; then
			sudo pip install fabric3 -y
		fi
	fi

	#get github information
	if ! type git --version > /dev/null;  then
		read -p "Install GITHUB now?  [y]"  awsvar
		if [[ "${awsvar}" == "y" || ""  ]]; then
			sudo yum install git -y
		fi
	fi

	#get tmux information
	if ! type tmux --version > /dev/null;  then
			sudo yum install tmux -y
	fi
	#get screen information
	if ! type screen --version > /dev/null;  then
			sudo yum install screen -y
	fi

	yum install -y htop

echo "

"
echo "Type 'aws configure' to configure the AWS CLI, you will need your Amazon ID and secret KEY"
echo "
    Programs installed:
	htop
	screen
	tmux
	fabric3
	AWS cli
	Git
	"

}




Cluster_setup() {
	while IFS= read -r host; do
    ssh-copy-id -i ~/.ssh/id_rsa.pub "$host"
	done < hostnames_file

	exit 0;

	filename="/home/ec2-user/devops/servers.txt"
	#while read p; do
	#echo $p
	CMD="pssh -h $filename -l ec2-user sudo yum install ${args[1]}"
	echo "doing: " $CMD
	pssh -h $filename -l ec2-user sudo date
}




Test() {
	echo "nothing to do"
}

PerfSuite() {
	echo "perf suite started"

	#pick host to analyze?
	if [ "${1}" != "ALL" ]; then
		read -p "Which component?
		1: All
		2: Database
		3: Hosts
		4: Servers
		" choice
	else
		perfchoice=1
	fi

	if [ "${perfchoice}" == "1" ]; then
	#start TMUX session with all modules open

	echo "***********************************************"
	echo ""
	echo "checking tmux"
	#check tmux installed
	if ! type tmux > /dev/null;  then
		read -p "This program requires TMUX.  Install now?  [y]"  install
		((answer = ${install} =="y"? "y" : "n" ))
		if [[ "${answer}" == "n"  ]]; then
			exit 0
		else
			sudo pip install tmux
		fi
		read -p "Starting tmux session. Press 'Ctrl-B + D' to disconnect..."
	fi

	#Open 4 windows:

	tmux new-session -d -s dev -n dev
	#tmux send-keys 'bundle exec thin start' 'C-m'
	#tmux select-window -t dev:0
	tmux send-keys -t dev:0 "${syscheck} cpu" C-m
	tmux send-keys -t dev:0 "tmux set -g mode-mouse on" C-m
	tmux send-keys -t dev:0 "tmux set -g mouse-select-pane on" C-m
	tmux send-keys -t dev:0 "tmux set -g mouse-resize-pane on" C-m
	tmux send-keys -t dev:0 "clear" C-m

	tmux split-window -h
	tmux select-pane -t 1
	tmux send-keys -t 1 "${syscheck} help" C-m
	tmux split-window -v
	tmux select-pane -t 2
	tmux send-keys  -t 2 "${syscheck} disks" C-m
	#tmux split-window -v -t 1 '~/devops/devops nodes'
	tmux -2 attach-session -t dev

	fi


	if [ "${1}" != "2" ]; then
		echo "db metrics"
	#check database metrics / size / connections/ etc
	fi

	if [ "${1}" != "3" ]; then
	#check virtual hosts & network
	echo "virtual host check"

	fi

	if [ "${1}" != "4" ]; then
	#check client servers / agents
	echo "checking hosts 1"
	HostsCheck
	 #ssh $f uname -a;
	fi

}

StartAll(){
	#Can add this to bahsrc, for alias usage
	#will startup all programs and make sure all required daemons run
	echo "Starting up devops environment"

}


SystemsInfo(){

	if  ! grep --quiet devops_system_info ~/.bashrc ; then
		echo "no devops function found in basrhc."
		read -p "insert now?" insertoption
		if [[ "${insertoption}" == "y" || ""  ]]; then
			echo "alias devops_system_info='~/devops.sh -s'" >> ~/.bashrc
			source ~/.bashrc
		fi
	fi


	#cat all informational items into systeminfo.txt  >> kill file after reading
	#create systemInfo file (kill after displaying)
	#machine name, version, size, descriptor (aws), processors, and any other important information

	echo -e "\n"
	echo -e "\nKernel version: " ; cat /proc/version
	echo -e "\nHost name: " ; hostname
	echo -e " "
	echo -e "\nMachine information:" ; uname -a
	echo -e "\nUsers logged on:" ; w -h
	echo -e "\nCurrent date:" ; date
	echo -e "\nMachine status:" ; uptime
	echo -e "\nMemory status:" ; free
	echo -e "\nFilesystem status1:"; df -h
	echo -e "\nFilesystem Top dirs:"; du -cks * | sort -rn | head

    echo -e "\n"

	#in-depth metrics here:--------------
	# current network usage
	# pid and procs etc
	# Running ELK service
	# Runnig Python service
	# Running ... pid

}

disk(){
	echo "monitor disk space used and available"

echo -e "size of disks space" ;
du -cks * | sort -rn | head;



}

mem() {
	echo " free memory and java space memory:"
	vmstat
	free -m

}

cpu() {
	echo "checking cpu power...."
	iostat;


}

net() {
	netstat -plunt
	nmap localhost
	ss -s

}

monitor(){

#todo: 
#feeding scripted elements to ELK for monitoring
# similar to sensu as a a hand-rolled , single-pane solution for monitoring.

#check the running status capabilities
apachetop

}

nodes() {
	#check nodes
	filename="/home/ec2-user/devops/servers.txt"
	echo "
	Attempting to connect to nodes...
	"
	if [ ! -f "${hostfile}" ]; then
		echo "File not found!"
	else
	    #echo "Found: ${hostfile}";
	    for f in `cat ${hostfile}`;do
	    #echo "f is: $f";
	    ssh $f uname -a; done;
	fi;

}

devopscheck() {

#print versions of
#puppet
#python
#fabric
#AWS account
echo "checking devops environment"

}



dbperf()
{
 	#run database performance check
 	#run status on datbase, concurrent connections,
 	# check database stats: tables, size, connections, disk size, etc.
 	echo "database performance check"
 }

 data()
 {
	# check datamart size
	# report directories sorted
	# report largest files
	# report oldest & newest
	echo " data mart check"

}


checkuser()
{
	# get home directory
	# get github user name
	# get user keys
	# get user groups and associations
	# get user quota
	echo "checking user setup"
}



HostsCheck(){ 
	echo "starting hosts check"

	#for f in `cat $hostfile`; do echo `ssh -n $HOST "uname -a"`;

	if [ ! -f "${hostfile}" ]; then
		echo "File not found!"
	else
	    #echo "Found: ${hostfile}";
	    for f in `cat ${hostfile}`;do
	    #echo "f is: $f";
	    ssh $f uname -a; done;
	fi;
}


case "${option}" in
-i  ) Install ;;
-c  ) Cluster_setup ;;
-t  ) Test ;;
-p  ) PerfSuite;;
-s  ) SystemsInfo;;
-m  ) mem;;
-C  ) CPU;;
-n  ) net;;
-r  ) monitor;;
-d  ) devopscheck;;
-h )  Help;;
-q )  exit 0;;
0 | -A | --ALL ) PerfSuite ALL;;
esac

