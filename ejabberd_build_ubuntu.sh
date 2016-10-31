#!/bin/bash

# install lsb tools
sudo apt-get install -y -q lsb

# install openssl
sudo apt-get install -yq openssl

# install ssl library
sudo apt-get install -yq libssl-dev
# for readhats: sudo yum -y install openssl-devel

# install libyaml
sudo apt-get install -yq libyaml-dev 

# install latset version of erlang. 
# wget -c -O- http://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | sudo apt-key add -
# echo "deb http://packages.erlang-solutions.com/ubuntu $(lsb_release -cs) contrib" | sudo tee -a /etc/apt/sources.list.d/erlang_solutions.list > /dev/null
# sudo apt-get update
# sudo apt-get install -y -q erlang
# At the moment this is not possible, since OTP/19 is too recent 
# and not all of the libraries needed to write custom Ejabberd
# modules have been ported yet. Instead, install OTP/17, using
# a script written by Bryan Hunter. The original file is available 
# in GitHubGist. Here we use a customized version:
cd /tmp
wget 167.165.110.41:8000/build_erlang.sh
# Make the file executable and run it:
chmod u+x /tmp/build_erlang.sh
sudo /tmp/build_erlang.sh

# clone and build ejabberd from source
git clone https://github.com/processone/ejabberd.git /tmp/ejabberd
cd /tmp/ejabberd
sudo apt-get -y -q install autotools-dev
sudo apt-get -y -q install autoconf
./autogen.sh
./configure 
make
sudo make install 

# clone mod_restful and install it
cd ~/.ejabberd_modules/sources
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
sudo cp -R /lib/lager* /usr/lib/erlang/

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
sudo cp -R /tmp/fast_xml /usr/lib/erlang/lib

# clone mod_first_component and install it
# Need to move first to /tmp to be able to use nonsudo ssh keys
cd /tmp
# before the merge into the develop branch is done, copy the branch: 
git clone -b feature/G2-159-g2-component-startup-query-ejabbed ssh://git@scm.intamac.com:22/ejab/mod_first_component.git
# Later on, just pull from the default:
# git clone ssh://git@scm.intamac.com:22/ejab/mod_first_component.git
sudo mv mod_first_component ~/.ejabberd_modules/sources/
sudo ejabberdctl modules_update_specs
cd ~/.ejabberd_modules/sources/mod_first_component/
# Create an ebin directory for compiled beam files:
mkdir -p ebin
# Compile the module: 
sudo erlc -I /lib/ejabbberd*/include -pa /usr/lib/erlang/lager*/ebin -pa /usr/lib/erlang/fast_xml/ebin -o ebin src/*
# Create symlinks in ejabberd lib to the beams from the module:
cd /lib/ejabberd*/ebin
sudo ln -s /.ejabberd-modules/sources/mod_first_component/ebin/* /lib/ejabberd*/ebin
sudo ejabberdctl module_install mod_first_component 

# Fetch ejabberd config file from somewhere, for now just an ftp server
# running in my computer:
cd /tmp
wget 167.165.110.41:8000/ejabberd.yml
sudo mv /etc/ejabberd/ejabberd.yml /etc/ejabberd/ejabberd.backup.yml
sudo cp /tmp/ejabberd.yml /etc/ejabberd/

# Start the server:
# sudo ejabberdctl start
