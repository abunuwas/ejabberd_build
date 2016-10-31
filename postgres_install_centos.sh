sudo yum -y install postgresql-server postgresql-contrib

# One time startup
#sudo service postgresql initdb
sudo postgresql-setup initdb

# Start postgres deamon
sudo service postgresql start

# Allow md5-based authentication when connecting to db
# In lines 82 and 84 of pg_hba.conf we can specify the 
# authentication method to be used when connecting to a
# database IPv4 (line 82) and IPv6 (line 84). By default 
# this is set to ident-based authentiation. In both lines.
# Change ident for md5 to allow password-based authentiation. 
sed -i '82s/ident/md5/' /var/lib/pgsql/data/pg_hba.conf
sed -i '84s/ident/md5/' /var/lib/pgsql/data/pg_hba.conf

echo Password-based authentication enabled. 

# Allow remote connections on IPv4 and IPv6
sed -i '82s/127\.0\.0\.1\/32/0.0.0.0\/0/' /var/lib/pgsql/data/pg_hba.conf
sed -i '84s/\:\:1\/128/0.0.0.0\/0/' /var/lib/pgsql/data/pg_hba.conf

# Create admin user in postgres
sudo su - postgres -c "psql -c \"create user admin with password 'ejabberd';\""
sudo su - postgres -c "psql -c \"alter role admin with superuser\";"

echo Created user admin as superuser. 

# Create ejabberd database with ownership for admin
sudo su - postgres -c "psql -c \"create database ejabberd with owner admin;\""

echo Created database ejabberd with admin as owner. 

# Create .pgpass file to avoid being prompted for password when connecting
# to the db 
sudo touch ~/.pgpass
sudo echo  127.0.0.1:5432:ejabberd:admin:ejabberd >> ~/.pgpass

echo Created ~/.pgpass file. 

# Set permissions in .pgpass to u=rw as required by postgres
sudo chmod 0600 ~/.pgpass

echo Permissions on .pgpass file set to u=rw. 
