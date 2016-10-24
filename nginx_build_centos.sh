# Make sure EPEL repository is enabled
#sudo yum install -y epel-release

## Add port 9090 and 9091 to SELinux http and allow internal httpd connections
sudo semanage port -a -t http_port_t -p tcp 9091
sudo semanage port -m -t http_port_t -p tcp 9090
sudo setsebool -P httpd_can_network_connect 1

# Modify Iptables and open needed ports to accept HTTP requests from devices. These are:
# --> Port 9191 for access to Ejabberd's API with SSL. 
# --> Port 9090 for access to Ejabberd's API without SSL. This might not be what we want
#     in production. 
sudo iptables -I INPUT 5 -p tcp --dport 9091 -m state --state NEW,ESTABLISHED -j ACCEPT
sudo iptables -I INPUT 4 -p tcp --dport 9090 -m state --state NEW,ESTABLISHED -j ACCEPT
sudo iptables-save

# Install Nginix
sudo yum install -y nginx

#openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ./nginx.key -out ./nginx.crt -sub "/C=UK/ST=Northamptonshire/L=Northampton/O=Intamac Ltd/OU=Software/CM=Jose Haro/emailAddress=joseharoperalta@gmail.com"
#sudo chmod 400 nginx.ejabberd.*

# Create a directory for Nginx certificates
sudo mkdir /etc/nginx/certificates

# Fetch certificates and move them to the Nginx
# certificates' directory
cd /tmp
wget 167.165.110.139:8000/stgswann.cam.intamac.com.crt
wget 167.165.110.139:8000/stgswann.cam.intamac.com.key
sudo mv stgswann.cam.intamac.com.* /etc/nginx/certificates/

# Fetch Nginx config file for ejabberd to be placed in /etc/nginx/conf.d/ejabberd.conf
cd /tmp
wget 167.165.110.139:8000/ejabberd.conf
sudo mv /tmp/ejabbed.conf /etc/nginx/conf.d/ejabberd.conf

# Overwrite default additional Nginx configuration with custom proxy
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bk
sudo sed -i '36s/\*/ejabberd/' /etc/nginx/nginx.conf

# Bind domain stgswann.cam.intamac.com to localhost
echo swann.cam.intamac.com localhost >> /etc/hosts
