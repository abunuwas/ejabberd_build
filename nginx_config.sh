# Make sure EPEL repository is activated
sudo yum install -y epel-release

# Install Nginix
sudo yum install -y Nginix

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ./nginx.key -out ./nginx.crt -sub "/C=UK/ST=Northamptonshire/L=Northampton/O=Intamac Ltd/OU=Software/CM=Jose Haro/emailAddress=joseharoperalta@gmail.com"

sudo chmod 400 nginx.ejabberd.*

sudo mkdir /etc/nginx/certificates

cp nginx.ejabberd.* /etc/nginx/certificates/

# Fetch from somwhere Nginx config file for ejabberd to be placed in /etc/nginx/conf.d/ejabberd.conf

