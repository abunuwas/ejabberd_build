
sudo yum install -y -q epel-release 

sudo yum -y -q update

# yum-utils
sudo yum -y -q install yum-utils

# development tools
sudo yum groupinstall -y -q "Development Tools"

# ssl libraries
sudo yum install -y -q openssl openssl-devel openssl-libs

# libyaml
sudo yum install -y -q libyaml libyaml-devel 

# automake
sudo yum -y -q install automake

# autoconf  
sudo yum -y -q install autoconf

# curses
sudo yum -y -q install ncurses-devel

# expat XML parser
sudo yum -y -q install expat expat-devel

# iptables service
sudo yum -y -q install iptables-services

# enable iptables-service
sudo systemctl enable iptables