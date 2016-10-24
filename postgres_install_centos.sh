sudo yum -y install postgresql-server postgresql-contrib

# One time startup
sudo service postgresql initdb

# Start postgres deamon
sudo service postgresql start

# Allow md5-based authentication when connecting to db
sed -i '82s/ident/md5/' /var/lib/pgsql/data/pg_hba.conf
sed -i '84s/ident/md5/' /var/lib/pgsql/data/pg_hba.conf

# Create admin user in postgres
sudo su - postgres -c "psql -c \"create user admin with password 'ejabberd';\""
sudo su - postgres -c "psql -c \"alter role admin with superuser\";"

# http://stackoverflow.com/questions/6523019/postgresql-scripting-psql-execution-with-password
# try the ~/.pgpass file

# Create ejabberd database with ownership for admin
sudo su - postgres -c "psql -c \"create database ejabberd with owner admin;\""

psql -h localhost -d ejabberd -U admin < /lib/ejabberd*/priv/sql/lite.sql
