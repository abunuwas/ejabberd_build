# Give ownership of all Ejabberd related resources to user Ejabberd
sudo chown -R ejabberd:ejabberd /etc/ejabberd
sudo chown -R ejabberd:ejabberd /var/lib/ejabberd
sudo chown -R ejabberd:ejabberd /var/log/ejabberd
sudo chown -R ejabberd:ejabberd /var/lock/ejabberdctl
sudo chown ejabberd:ejabberd /sbin/ejabberdctl

# Copy the erlang cookie into Ejabberd's home directory
sudo cp ~/.erlang.cookie /home/ejabberd/.erlang.cookie
sudo chown ejabberd:ejabberd /home/ejabberd/.erlang.cookie
sudo chmod 400 /home/ejabberd/.erlang.cookie

# Delete mnesia cache
sudo rm -rf /var/lib/ejabberd/*