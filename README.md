# EJABBERD BUILD SCRIPTS

----

The scripts in this repository make a full build and configuration of the Ejabberd server as required in our platform. This includes setup of the PostgreSQL database and the Nginx proxy server which are required by our configuration of Ejabberd.

In their current state, these scripts are limited in their configuration capabilities and assume all resources should be created in the same box. 

Because the operating system that we run in our servers is CentOS 7, these scripts are designed to work in that environment. Some work has been done to port them to Ubuntu, but at the moment is far from complete. 

To get started with these scripts, follow the steps described below to prepare your environment:

1. Get a fresh installation of CentOS 7. An existing installation is also fine, but make sure it's CentOS 7.

2.  Make sure you're connected to the Internet. 

3. Open a terminal. 

4. Log as root:

    `$ sudo -i`

5. Create an ssh key:

    `$ ssh-keygen -t rsa -b 4096 -C "<your-email>"`

6. Add the ssh key to the ssh-agent so you're not prompted for the passphrase every time you use it:

	```bash 
	$ eval $(ssh-agent -s) # start the ssh-agent in the background

	$ ssh-add ~/.ssh/id_rsa # add the ssh key to the ssh-agent 
	```

7. Add the key to your Bitbucket account so you can use it to pull repositories. 

8. Install git:

	`$ yum install -y git`

	** NB: in a fresh installation yum will be locked by PackageKit. Executing yum will reveal the id of the process, so just kill it:

	`$ kill -9 <pid>`

9. Clone this repository.

10. Run the main script, `ejabberd_build_centos.sh`, giving it the address of an ftp server to pull the config files from:

	`$ ./ejabberd_build_centos.sh <ip-of-ftp-server>`

	Optionally you can run in debugging mode to see everything that's happening:

	`$ bash -x ./ejabberd_build_centos.sh`


# How it works

----

## Scripts 

The whole build process is organized in four scripts:

1. *ejabberd_build_centos.sh*: this script is the entry point of the process. It takes care of major configurations, building Ejabberd, and executing the scripts listed below.

2. *build-erlang-17.0_centos.sh*: this script builds Erlang 17 for CentOS.

3. *postgres_install_centos.sh*: this script installs and configures postgres. It also creates a user admin and a database ejabberd with the schema required to work with Ejabberd.

4. *nginx_build_centos.sh*: this script installs and configures Nginx to work as a reversed proxy for the Restful API of Ejabberd (through mod_restful).

## What they do

1. First off the main script install the main system dependencies needed to make the builds.

2. Next the main script executes the script that builds erlang.

3. Next a user ejabberd is created who'll own all resources related to Ejabberd.

4. Ports 5222, 5280, 888, and 4369 are opened by modifying the iptables configuration.

5. Main script executes the script that installs and configures PostgreSQL. This script, in turn:

	- Installs, initializes, and starts PostgreSQL as a service.
	- Modifies /var/lib/pgsql/data/pg_hba.conf to allow password-based login and remote connections.
	- Creates an admin user and promotes the user to superuser.
	- Creates database ejabberd with owned by admin. 
	- Creates a .pgpass file to use when connecting to ejabberd database without being prompted for passord.

6. Clones Ejabberd repository and builds from source. Ejabberd is configured to run using PostgreSQL. 

7. Increases ulimits for Ejabberd.

8. Connects to the ejabberd database as admin and executes the schema creation script provided by Ejabberd.

9. Starts Ejabberd.

10. Installs required modules mod_restful and mod_first_component, together with libraries they depend on (rebar3, lager, and fast_xml).

11. Fetches the following configuration files and scripts:

	- ejabberd.yml (for /etc/ejabberd/ejabberd.yml).
	- ejabberdctl.cfg (for /etc/ejabberd/ejabberdctl.cfg).
	- ejabberd (for /etc/init.d/ejabberd).
	- ejabberd.pem (for /etc/ejabberd/ejabberd.pem).

12. Customizes EPMD value in /sbin/ejabberdctl to point to /usr/local/epmd.

13. Gives ownership of all Ejabberd-related resources to user ejabberd.

14. Removes cache from /var/lib/ejabberd/*.

15. Executes script that installs and configures Nginx. This script:

	- Opens ports 9091 and 9090 by modifying the iptables configuration.
	- Installs Nginx.
	- Fetches certificates stgswann.cam.intamac.com and stgswann.cam.intamac.com.key and places them under /etc/nginx/certificates.
	- Fetches configuration file ejabberd.conf and places it under /etc/nginx/conf.d
	- Updates /etc/nginx/nginx.conf file to include ejabberd.conf.
	- Adds swann.cam.intamac.com to the list of hosts linked to 127.0.0.1. 

16. Restarts Ejabberd with the script /etc/init.d/ejabberd

17. Starts Nginx.

# How to test if everything is working properly?

----

1. Install nmap to check if the expected ports (5222, 8888, 5280, 4369, 9090, 9091, 5432) are open in your machine. You can test for 888 like this: 

	`$ nmap -Pn 8888 <ip-of-centos-with-ejabberd>`

2. Check the state of the services involved in the CentOS machine:

	```bash
	$ sudo service postgresql status
	$ sudo service nginx status
	$ sudo ejabberdctl status
	$ sudo service iptables status
	```

3. See if the CentOS machine recognizes the desired ports as opened:

	`$ nmap -sT -O localhost`

4. Try to connect a component or a client to the server. 

5. See if the ejabberd database has the right schema:

	```bash
	$ psql -h 127.0.0.1 -d ejabberd -U admin
	$ ejabberd=# \dt
	```

# TODO

----

1. Make sure services restart themselves after a reboot.

2. Make sure the API through Nginx works as expected.

3. Make sure the Ejabberd install from these scripts supports clustering.

4. Make sure iptables are never broken. 

5. Add flexibility for configuration. 


# TO CONSIDER

The following lines might be needed for SELinux to work well with Nginx config files:

```bash
# Set the security context of files needed when running Nginx
sudo /sbin/restorecon -v /etc/nginx/certificates/stgswann.cam.intamac.com.crt
sudo /sbin/restorecon -v /etc/nginx/certificates/stgswann.cam.intamac.com.key
sudo /sbin/restorecon -v /etc/nginx/conf.d/ejabberd.conf
```

These lines should be placed just before the command that restarts Nginx at the end of the script `ejabberd_build_centos.sh`, in line 272. 