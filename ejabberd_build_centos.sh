#!/bin/bash

######################################################
######################################################
## Ensure the .ssh directory of the user which is
## running the following commands has the valid
## ssh keys to pull from the Intamac Bitbucket server.
######################################################
######################################################

# Install development tools
sudo yum groupinstall -y "Development Tools"

# Enable EPEL repo
cd /tmp
wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-8.noarch.rpm
sudo rpm -ivh epel-release-7-8.noarch.rpm
sudo yum update 

# Ensure Python3 is installed. For this, first install IUS repo
sudo yum -y install https://centos7.iuscommunity.org/ius-release.rpm
sudo yum update

# Install pythyon3.5 from that repository
#sudo yum install -y python35u python35u-libs python35u-devel python35u-pip

# install lsb tools
#sudo yum install -y -q redhat-lsb-core

# install openssl
sudo yum install -y -q openssl

# install ssl library
sudo yum install -y -q openssl-devel
# for readhats: sudo yum -y install openssl-devel

# install libyaml
sudo yum install -y -q libyaml-devel 

# install latset version of erlang. 
# wget -c -O- http://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | sudo apt-key add -
# echo "deb http://packages.erlang-solutions.com/ubuntu $(lsb_release -cs) contrib" | sudo tee -a /etc/apt/sources.list.d/erlang_solutions.list > /dev/null
# sudo yum update
# sudo yum install -y -q erlang
# At the moment this is not possible, since OTP/19 is too recent 
# and not all of the libraries needed to write custom Ejabberd
# modules have been ported yet. Instead, install OTP/17, using
# a script written by Bryan Hunter. The original file is available 
# in GitHubGist. Here we use a customized version:
#cd /tmp
#wget 167.165.110.139:8000/build_erlang.sh
# Make the file executable and run it:
#chmod u+x /tmp/build_erlang.sh
#sudo /tmp/build_erlang.sh

# clone and build ejabberd from source
git clone https://github.com/processone/ejabberd.git /tmp/ejabberd
cd /tmp/ejabberd
#sudo yum -y -q install autotools-dev
sudo yum -y -q install automake 
sudo yum -y -q install autoconf
./autogen.sh
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
# Need to move first to /tmp to be able to use nonsudo ssh keys
cd /tmp
# before the merge into the develop branch is done, copy the branch: 
#git clone -b feature/G2-159-g2-component-startup-query-ejabbed ssh://git@scm.intamac.com:22/ejab/mod_first_component.git
# Later on, just pull from the default:
if [ -d mod_first_component ]; then
	sudo rm -rf mod_first_component
fi 
git clone -b develop ssh://git@scm.intamac.com:22/ejab/mod_first_component.git
# Enter passphrase for key '/root/.ssh/id_rsa': 
sudo mv /tmp/mod_first_component ~/.ejabberd-modules/sources
# sudo ejabberdctl modules_update_specs
cd ~/.ejabberd-modules/sources/mod_first_component/

# Create an ebin directory for compiled beam files:
mkdir -p ebin

# Compile the module: 
sudo erlc -I /lib/ejabberd*/include -pa /usr/local/lib/erlang/lager*/ebin -pa /usr/local/lib/erlang/lib/fast_xml/ebin -o ebin src/*
echo mod_first_component modules compiled.

# Create symlinks in ejabberd lib to the beams from the module:
cd /lib/ejabberd*/ebin
sudo ln -s /.ejabberd-modules/sources/mod_first_component/ebin/mod_first_component.beam #/lib/ejabberd*/ebin
sudo ln -s /.ejabberd-modules/sources/mod_first_component/ebin/mod_first_component_utils.beam #/lib/ejabberd*/ebin
echo Created symbolic links from ejabberd/ebin to mod_first_component beam files. 

sudo ejabberdctl module_install mod_first_component 
echo Installed mod_first_component. 

# Fetch ejabberd config file from somewhere, for now just an ftp server
# running in my computer:
cd /tmp
wget 167.165.110.139:8000/ejabberd.yml
sudo mv /etc/ejabberd/ejabberd.yml /etc/ejabberd/ejabberd.backup.yml
sudo cp /tmp/ejabberd.yml /etc/ejabberd/

# Start the server:
sudo ejabberdctl restart