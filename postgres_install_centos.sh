sudo yum -y install postgresql-server postgresql-contrib

# One time startup
sudo service postgresql-setup initdb

# Start postgres deamon
sudo service postgresql start

# Create admin user in postgres
sudo su - postgres -c "psql -c \"create user admin with password ejabberd\""
sudo su - postgres -c "psql -c \"alter role admin with superuser\""

# Create ejabberd database with ownership for admin
sudo su - postgres -c "psql -c \"create database ejabberd with owner admin\""

