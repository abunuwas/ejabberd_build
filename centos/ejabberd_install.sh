#!/bin/bash

######################################################
######################################################
## Ensure the .ssh directory of the user which is
## running the following commands has the valid
## ssh keys to pull from the Intamac Bitbucket server.
## Also add the ssh to the ssh-agent so that we don't
## need to provide the passphrase:
# $ eval "($ssh-agent -s)"
# $ eval ($ssh-agent -s)
# $ ssh-add ~/.ssh/id_rsa 
######################################################
######################################################

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Script directory: $SCRIPT_DIR"

S3=$1

server_ip=$2

if [ -z $server_ip ]; then
	server_ip=127.0.0.1
fi

if [ -z $S3 ]; then
	S3=S3://
fi

# install latset version of erlang. 
# wget -c -O- http://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | sudo apt-key add -
# echo "deb http://packages.erlang-solutions.com/ubuntu $(lsb_release -cs) contrib" | sudo tee -a /etc/apt/sources.list.d/erlang_solutions.list > /dev/null
# sudo yum update
# sudo yum install -y -q erlang
# At the moment this is not possible, since OTP/19 is too recent 
# and not all of the libraries needed to write custom Ejabberd
# modules have been ported yet. Instead, install OTP/17:
sudo chmod u+x erlang_install.sh
sudo bash -x ./erlang_install.sh 2>&1


create_user () {
	user=$1
	password=$2

	sudo useradd $user

	# Use usermod to set the password without interactive prompt
	# >> syntax: usermod --password <password> <user>
	sudo usermod --password $user $password
}


open_ports_ejabberd () {
	# Modify Iptables to open ports needed for Ejabberd. These are:
	# --> Port 5222 for client connections
	# --> Port 5280 for ejabberd_http
	# --> Port 8888 for component connection
	# --> Port 4369 for inter-cluster communication

	echo 'Setting up iptables to open ports 5222, 5280, 8888, and 4369'

	sudo iptables -I INPUT 4 -p tcp --dport 5222 -m state --state NEW,ESTABLISHED -j ACCEPT
	sudo iptables -I INPUT 4 -p tcp --dport 5280 -m state --state NEW,ESTABLISHED -j ACCEPT
	sudo iptables -I INPUT 4 -p tcp --dport 8888 -m state --state NEW,ESTABLISHED -j ACCEPT
	sudo iptables -I INPUT 4 -p tcp --dport 4369 -m state --state NEW,ESTABLISHED -j ACCEPT
	sudo iptables-save
	sudo service iptables save 
}


# Purely for testing in isolation, create postgres database
cd $SCRIPT_DIR
sudo chmod +x postgres_install_centos.sh 
sudo bash -x ./postgres_install_centos.sh 2>&1


build_ejabberd () {
	# Clone and build ejabberd from source
	git clone https://github.com/processone/ejabberd.git /tmp/ejabberd
	cd /tmp/ejabberd

	# Remove traces from previous installations, if any
	sudo make clean 
	./autogen.sh

	# Configure Ejabberd to use PostgreSQL 
	./configure --enable-pgsql
	sudo make
	sudo make install
}
 

increase_ulimits () {
	# Increase ulimits 
	sudo touch /etc/security/limits.d/100-ejabberd.conf
	sudo echo ejabberd hard nofile 50000 >> /etc/security/limits.d/100-ejabberd.conf
	sudo echo ejabberd soft nofile 50000 >> /etc/security/limits.d/100-ejabberd.conf
	sudo echo ejabberd hard nproc 30000 >> /etc/security/limits.d/100-ejabberd.conf
	sudo echo ejabberd soft nproc 30000 >> /etc/security/limits.d/100-ejabberd.conf	
}


create_db_schema () {
	# Create database schema using the file provided by Ejabberd 
	host=$1
	user=$2
	db=$3

	echo 'Created database schema' 
	psql -h $host -d $db -U $user < /lib/ejabberd*/priv/sql/lite.sql
}


# Start ejabberd server
sudo ejabberdctl start
sleep 2
echo $(sudo ejabberdctl status)


setup_nginx () {
	# Install and configure Nginx
	cd $SCRIPT_DIR
	sudo chmod +x nginx_build_centos.sh
	sudo bash -x ./nginx_build_centos.sh 2>&1	
}


# Start the server:
sudo /etc/init.d/ejabberd start

# Start Nginx
#sudo /etc/init.d/nginx start
sudo systemctl start nginx

set_chkconfig () {
	ejabberd=$1
	nginx=$2

	
}


create_user ejabberd ejabberd
open_ports_ejabberd
build_ejabberd
increase_ulimits
create_db_schema host 'ejabberd' ejabberd 
setup_nginx
set_chkconfig

#set services to start on boot
sudo /sbin/chkconfig --add ejabberd
sudo /sbin/chkconfig nginx on

# Start services once again just in case
sudo service nginx start
sudo ejabberdctl start 

# Make sure the iptables are loaded and working
sudo service iptables reload
sudo service iptables start 
