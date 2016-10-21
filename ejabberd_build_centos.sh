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
# $ ssh-agent add ~/.ssh/id_rsa 
######################################################
######################################################

#####################################################
## Install packages necessaries for the installations
#####################################################

# Enable EPEL repo
#cd /tmp
#wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-8.noarch.rpm
#sudo rpm -ivh epel-release-7-8.noarch.rpm
#sudo yum update 
sudo yum install -y epel-release 

# development tools
sudo yum groupinstall -y "Development Tools"

# openssl
sudo yum install -y -q openssl

# ssl library
sudo yum install -y -q openssl-devel
# for readhats: sudo yum -y install openssl-devel

# libyaml
sudo yum install -y -q libyaml-devel 

# automake
sudo yum -y -q install automake

# autoconf  
sudo yum -y -q install autoconf

# install latset version of erlang. 
# wget -c -O- http://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | sudo apt-key add -
# echo "deb http://packages.erlang-solutions.com/ubuntu $(lsb_release -cs) contrib" | sudo tee -a /etc/apt/sources.list.d/erlang_solutions.list > /dev/null
# sudo yum update
# sudo yum install -y -q erlang
# At the moment this is not possible, since OTP/19 is too recent 
# and not all of the libraries needed to write custom Ejabberd
# modules have been ported yet. Instead, install OTP/17:
cd /tmp
wget 167.165.110.139:8000/build-erlang-17.0_centos.sh
# Make the file executable and run it:
chmod u+x /tmp/build-erlang-17.0_centos.sh
sudo /tmp/build-erlang-17.0_centos.sh

# Create Ejabberd user 
sudo useradd ejabberd
sudo passwd ejabberd

# Modify Iptables to open ports needed for Ejabberd. These are:
# --> Port 5222 for client connections
# --> Port 5280 for ejabberd_http
# --> Port 8888 for component connection
# --> Port 4369 for inter-cluster communication
sudo iptables -I INPUT -p tcp --dport 5222 -m state --state NEW,ESTABLISHED -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 5280 -m state --state NEW,ESTABLISHED -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 8888 -m state --state NEW,ESTABLISHED -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 4369 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables-save

# Clone and build ejabberd from source
git clone https://github.com/processone/ejabberd.git /tmp/ejabberd
cd /tmp/ejabberd
./autogen.sh
# Configure Ejabberd to use PostgreSQL 
./configure --enable-pgsql
make
sudo make install 

# Start ejabberd server
sudo ejabberdctl start

# clone mod_restful and install it
cd ~/.ejabberd-modules/sources
sudo git clone https://github.com/jadahl/mod_restful.git
sudo ejabberdctl modules_update_specs
sudo ejabberdctl module_install mod_restful

# Install rebar3
git clone https://github.com/erlang/rebar3.git /tmp/rebar3
cd /tmp/rebar3
./bootstrap
./rebar3 local install
sudo echo export PATH=$PATH:~/.cache/rebar3/bin >> ~/.bashrc
export PATH=$PATH:~/.cache/rebar3/bin
#source ~/.bashrc

# Include lager in the erlang's lib directory
sudo cp -R /lib/lager* /usr/local/lib/erlang/

# Install fast_xml
git clone https://github.com/processone/fast_xml.git /tmp/fast_xml
# The latest version has a number of bugs, so checkout into a 
# previous release:
cd /tmp/fast_xml 
git checkout tags/1.1.13
# Install
./configure 
sudo make
# Copy the library into the erlang's lib directory
sudo cp -R /tmp/fast_xml /usr/local/lib/erlang/lib

# clone mod_first_component and install it
# before the merge into the develop branch is done, copy the branch: 
#git clone -b feature/G2-159-g2-component-startup-query-ejabbed ssh://git@scm.intamac.com:22/ejab/mod_first_component.git
# Later on, just pull from the default:
cd ~/.ejabberd-modules/sources
if [ -d mod_first_component ]; then
	sudo rm -rf mod_first_component
fi 
git clone -b develop ssh://git@scm.intamac.com:22/ejab/mod_first_component.git
#sudo mv /tmp/mod_first_component ~/.ejabberd-modules/sources
# sudo ejabberdctl modules_update_specs
cd ~/.ejabberd-modules/sources/mod_first_component/

# Create an ebin directory for compiled beam files:
mkdir -p ebin

# Compile the module: 
sudo erlc -I /lib/ejabberd*/include -pa /usr/local/lib/erlang/lager*/ebin -pa /usr/local/lib/erlang/lib/fast_xml/ebin -o ebin src/*
echo mod_first_component modules compiled.

# Create symlinks in ejabberd lib to the beams from the module:
cd /lib/ejabberd*/ebin
sudo ln -s /.ejabberd-modules/sources/mod_first_component/ebin/mod_first_component.beam 
sudo ln -s /.ejabberd-modules/sources/mod_first_component/ebin/mod_first_component_utils.beam 
echo Created symbolic links from ejabberd/ebin to mod_first_component beam files. 

sudo ejabberdctl module_install mod_first_component 
echo Installed mod_first_component. 


#####################
## Fetch config files
## At the moment just using a local network 
#####################

# Fetch ejabberd.yml config file 
cd /tmp
wget 167.165.110.139:8000/ejabberd.yml
sudo mv /etc/ejabberd/ejabberd.yml /etc/ejabberd/ejabberd.yml.bk
sudo cp /tmp/ejabberd.yml /etc/ejabberd/

# Fetch ejabberdctl.cfg file
cd /tmp
wget 167.165.110.139:8000/ejabberdctl.cfg
sudo mv /etc/ejabberd/ejabberdctl.cfg /etc/ejabberd/ejabberdctl.cfg.bk
sudo cp /tmp/ejabberd.yml /etc/ejabberd/

# Fetch init file for Ejabberd
cd /tmp
wget 167.165.110.139:8000/ejabberd
sudo mv /tmp/ejabberd /etc/init.d/
sudo +x /etc/init.d/ejabberd 

# Modify /sbin/ejabberdctl as follows
sudo cp /sbin/ejabberdctl /etc/ejabberd/ejabberdct.sbin.bk
sudo sed -i '/EPMD=*/c\EPMD=/usr/local/bin/epmd' /sbin/ejabberdctl

# Fetch ejabberd certificate
cd /tmp
wget 167.165.110.139:8000/ejabberd.pem
sudo chmod 400 ejabberd.pem
sudo mv ejabberd.pem /etc/ejabberd/

# Give ownership of all Ejabberd related resources to user Ejabberd
sudo chown -R ejabberd:ejabberd /etc/ejabberd
sudo chown -R ejabberd:ejabberd /var/lib/ejabberd
sudo chown -R ejabberd:ejabberd /var/log/ejabberd
sudo chown -R ejabberd:ejabberd /var/lock/ejabberdctl
sudo chown ejabberd:ejabberd /sbin/ejabberdctl

# Copy the erlang cookie into Ejabberd's home directory
sudo cp ~/erlang.cookie /home/ejabberd/.erlang.cookie
sudo chown ejabberd:ejabberd /home/ejabberd/.erlang.cookie
sudo chmod 400 /home/ejabberd/.erlang.cookie

# Delete mnesia cache
sudo rm -rf /var/lib/ejabberd/*

# Install and configure Nginx
cd /tmp
wget 167.165.110.139:8000/nginx_config.sh
sudo ./nginx_config.sh

# Start the server:
sudo /etc/init.d/ejabberd start

# Start Nginx
sudo /etc/initd./nginx start


############################################################################
############################################################################
############################################################################
# Ensure Python3 is installed. For this, first install IUS repo
#sudo yum -y install https://centos7.iuscommunity.org/ius-release.rpm
#sudo yum update

# Install pythyon3.5 from that repository
#sudo yum install -y python35u python35u-libs python35u-devel python35u-pip
