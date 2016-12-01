##############################################
## Fetch config files                       ##
## At the moment just using a local network ## 
##############################################

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
sudo chmod +x /etc/init.d/ejabberd 

# Modify /sbin/ejabberdctl as follows
sudo cp /sbin/ejabberdctl /etc/ejabberd/ejabberdctl.sbin.bk
sudo sed -i '16s/.*/EPMD=\/usr\/local\/bin\/epmd/' /sbin/ejabberdctl

# Fetch ejabberd certificate
cd /tmp
wget 167.165.110.139:8000/ejabberd.pem
sudo chmod 400 ejabberd.pem
sudo mv ejabberd.pem /etc/ejabberd/