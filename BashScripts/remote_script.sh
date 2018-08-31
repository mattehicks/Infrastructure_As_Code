#!/bin/bash

# utilities to be called from base_script.sh on deployment server

hosts_path="/etc/hosts"
accesslogs_path="/var/log/tdcustom/accesslogs/"
vhosts_path="/etc/apache2/sites-available/"
vhost_skeleton_path="$current_directory/vhost.skeleton.conf"
web_root="/var/www/"




InstallGithub(){
	#link new servers to github

	if ! type git --version > /dev/null;  then
		read -p "Install GITHUB now?  [y]"  awsvar
		if [[ "${awsvar}" == "y" || ""  ]]; then
			sudo yum install git -y
		fi
	fi

	#sudo yum install git-core
	git config --global user.name "Server"
	git config --global user.email "server@server.com"


}


InstallWebserver_Apache(){

	sudo apt-get install -y apache2

	#sudo service httpd start
	sudo groupadd www
	sudo usermod -a -G www ubuntu
	sudo chown -R root:www /var/www
	sudo chmod 2775 /var/www
	find /var/www -type d -exec sudo chmod 2775 {} +
	find /var/www -type f -exec sudo chmod 0664 {} +

		# create index file
		indexfile="/var/www/index.html"
		touch $indexfile
		echo "<html><head></head><body>Welcome!</body></html>" >> "$indexfile"

	# update vhost
	vhost=`cat "$vhost_skeleton_path"`
	vhost=${vhost//@site_url@/$site_url}
	vhost=${vhost//@site_docroot@/$absolute_doc_root}
	 
	`touch $vhosts_path$site_url.conf`
	echo "$vhost" > "$vhosts_path$site_url.conf"
	echo "Updated vhosts in Apache config"


}

InstallWebserver_Nginx(){

	sudo yum -y install epel-release
	sudo yum -y install nginx
	sudo yum -y install httpd-tools

	sudo htpasswd -c /etc/nginx/htpasswd.users kibanaadmin

	sudo gedit /etc/nginx/nginx.conf /// CONFIGURE NGINX TO SERVE KIBANA
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

}



