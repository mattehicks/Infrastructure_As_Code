#teradata script
## Created by Matt Hicks
## 2017 mattehicks@gmail.com

# start instances
# install git on all 
# install credentials on all
# pull repo on all
# execute remote commands 
# setup: install/configure webservers 


#webserver must not runa s root
#webserver return "hello world" page



AMI_ID="ami-7a85a01a"
VPC_ID="vpc-xxxxxxxx"
SUBNET_ID="subnet-xxxxxxxx"
SECURITY_GROUP_ID="sg-xxxxxx"

ELB_NAME=TDELB1
VPC_NAME=TDVPC1
INSTANCE_COUNT=1

EC2_TAG="TDtest"

current_directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

hosts_path="/etc/hosts"
accesslogs_path="/var/log/tdcustom/accesslogs/"
vhosts_path="/etc/apache2/sites-available/"
vhost_skeleton_path="$current_directory/vhost.skeleton.conf"
web_root="/var/www/"


Help() {
	echo " Purpose is to install utilities and a robust ADMIN WORKSTATION on this machine"
	echo " Additionally; automated status and performance checking of this environment"
	echo " This program will confirm before it will install anything."
	exit 0
}


# install webserver
@apache

with pssh:

using /file.hosts
hostfile="/home/ec2-user/devops/servers.txt"


for all in $file
{
# install apache on all new servers
sudo yum update –y

sudo yum install -y httpd24 php56 php56-mysqlnd
#sudo service httpd start
sudo groupadd www
sudo usermod -a -G www ec2-user
sudo chown -R root:www /var/www
sudo chmod 2775 /var/www
find /var/www -type d -exec sudo chmod 2775 {} +
find /var/www -type f -exec sudo chmod 0664 {} +

..............

# create directory on the remote server if it doesn't exists
if [ ! -d "$absolute_doc_root" ]; then
 
	# create directory
	`mkdir "$absolute_doc_root/"`
	`chown -R $SUDO_USER:staff "$absolute_doc_root/"`
 
	# create index file
	indexfile="$absolute_doc_root/index.html"
	`touch "$indexfile"`
	echo "<html><head></head><body>Welcome!</body></html>" >> "$indexfile"
 
	echo "Created directory $absolute_doc_root/"
fi

..............

# update vhost
vhost=`cat "$vhost_skeleton_path"`
vhost=${vhost//@site_url@/$site_url}
vhost=${vhost//@site_docroot@/$absolute_doc_root}
 
`touch $vhosts_path$site_url.conf`
echo "$vhost" > "$vhosts_path$site_url.conf"
echo "Updated vhosts in Apache config"

........................
	
# update hosts file
echo 127.0.0.1    $site_url >> $hosts_path
echo "Updated the hosts file"

...............

check for ssh keys..
read key file?
while IFS= read -r host; do
    ssh-copy-id -i ~/.ssh/id_rsa.pub "$host"
done < hostnames_file
while IFS= read -r host;do
    ssh "$host" 'sudo apt-get install puppet' # also, modify puppet.conf
end < hostnames_file

}



Create ELB
HTTP : 80
HTTPS : 443

Register all 3 webservers with ELB

networking
my laptop SSH allowed
141.206.246.10/32  can SSH
all other ports disabled

# restart apache
echo "Enabling site in Apache..."
echo `a2ensite $site_url`
 
echo "Restarting Apache..."
echo `/etc/init.d/apache2 restart`
deploy the webserver:
for all hosts{

rsync /vhosts.txt user@hostname


}


# @site_url@
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot "@site_docroot@"
    ServerName @site_url@
    ServerAlias www.@site_url@
    ErrorLog "logs/@site_url@-error_log.log"
    CustomLog "logs/@site_url@-access_log.log" common
    <Directory "@site_docroot@">
        Require all granted
        AllowOverride All
  </Directory>
</VirtualHost>

#make the file executable
chmod u+x /path/to/script/addvhost.sh





aws ec2 run-instances
 --image-id ami-12345678
 --region eu-west-1
 --instance-type t1.micro
 --key-name MyKeyPair


install NGINX:

**********************************  INSTALL NGINX *********************************
$ sudo yum -y install epel-release
$ sudo yum -y install nginx
$ sudo yum -y install httpd-tools
$ sudo htpasswd -c /etc/nginx/htpasswd.users kibanaadmin
$ sudo gedit /etc/nginx/nginx.conf /// CONFIGURE NGINX TO SERVE KIBANA
Remove the server block at the end (starts with server { ), the last configuration block in the file i.e. the last 2 conf lines in the file ‘d be:
include /etc/nginx/conf.d/*.conf;</div>
<div>}
Create a new kibana.conf in conf.d
sudo vi /etc/nginx/conf.d/kibana.conf
Paste the following lines into the file. Be sure to update the server_name to your server’s name and auth_basic_user_file to file path of your authentication file:
server {
listen 80;
server_name elk;auth_basic "Restricted Access";
auth_basic_user_file /etc/nginx/conf.d/elk.htpasswd;location / {
proxy_pass http://localhost:5601;
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection 'upgrade';
proxy_set_header Host $host;
proxy_cache_bypass $http_upgrade;
}
}
Save and exit. This configures Nginx to direct your server’s HTTP traffic to the Kibana application, which is listening on localhost:5601. Also, Nginx will use the elk.htpasswd file, that we created earlier, and require basic authentication.
Start and enable Nginx
$ sudo systemctl start nginx
$ sudo systemctl enable nginx
The output:
[nahmed@elk ~]$ sudo systemctl start nginx
[nahmed@elk ~]$ sudo systemctl enable nginx
Created symlink from /etc/systemd/system/multi-user.target.wants/nginx.service to /usr/lib/systemd/system/nginx.service.
Verification
Hit the http://localhost
