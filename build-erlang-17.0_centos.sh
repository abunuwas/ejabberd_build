#!/bin/bash
# Pull this file down, make it executable and run it with sudo
# wget https://gist.githubusercontent.com/bryanhunter/10380945/raw/build-erlang-17.0.sh
# chmod u+x build-erlang-17.0.sh
# sudo ./build-erlang-17.0.sh

if [ $(id -u) != "0" ]; then
echo "You must be the superuser to run this script" >&2
exit 1
fi

# Install the build tools (dpkg-dev g++ gcc libc6-dev make)
#yum -y install build-essential

# automatic configure script builder (debianutils m4 perl)
#yum -y install autoconf

# Needed for HiPE (native code) support, but already installed by autoconf
# yum -y install m4

# Needed for terminal handling (libc-dev libncurses5 libtinfo-dev libtinfo5 ncurses-bin)
#yum -y install ncurses5-devel

# For building with wxWidgets
yum -y install wxGTK mesa-libGL-devel libpng

# For building ssl (libssh-4 libssl-dev zlib1g-dev)
yum -y install libssh-devel

# ODBC support (libltdl3-dev odbcinst1debian2 unixodbc)
yum -y install unixodbc-dev
mkdir -p ~/code/erlang
cd ~/code/erlang
 
if [ -e otp_src_17.4.tar.gz ]; then
echo "Good! 'otp_src_17.4.tar.gz' already exists. Skipping download."
else
wget http://www.erlang.org/download/otp_src_17.4.tar.gz
fi
tar -xvzf otp_src_17.4.tar.gz
chmod -R 777 otp_src_17.4
cd otp_src_17.4
./configure
make
make install

sudo cp /usr/local/bin/erl /bin/
sudo cp /usr/local/bin/erlc /bin/

exit 0