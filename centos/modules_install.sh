

# Create directory for Ejabberd modules if it doesn't alreay exist
sudo mkdir -p ~/.ejabberd-modules/sources


install_mod_restful () {
	# clone mod_restful and install it
	cd ~/.ejabberd-modules/sources
	if [ -d mod_restful ]; then
		sudo rm -rf mod_restful
	fi 
	sudo git clone https://github.com/jadahl/mod_restful.git
	sudo ejabberdctl modules_update_specs
	sudo ejabberdctl module_install mod_restful	
}


install_rebar3 () {
	# Install rebar3
	if [ -d /tmp/rebar3 ]; then 
		sudo rm -rf /tmp/rebar3
	fi
	git clone https://github.com/erlang/rebar3.git /tmp/rebar3
	cd /tmp/rebar3
	# Modify shebang to point to the right directory
	sed -i '1s/.*/#!\/usr\/local\/bin\/escript/' bootstrap
	./bootstrap
	sed -i '1s/.*/#!\/usr\/local\/bin\/escript/' rebar3
	./rebar3 local install
	sudo cp -R /tmp/rebar3 /usr/local/lib/erlang/lib
	sudo ln -s /usr/local/lib/erlang/lib/rebar3/rebar3 /usr/local/bin/rebar
	#sudo echo export PATH=$PATH:~/.cache/rebar3/bin >> ~/.bashrc
	#export PATH=$PATH:~/.cache/rebar3/bin
	#source ~/.bashrc	
}


install_fast_xml () {
	# Install fast_xml
	if [ -d /tmp/fast_xml ]; then
		sudo rm -rf /tmp/fast_xml
	fi 
	git clone https://github.com/processone/fast_xml.git /tmp/fast_xml
	# The latest version has a number of bugs, so checkout into a 
	# previous release:
	cd /tmp/fast_xml 
	git checkout tags/1.1.13
	# Install
	./configure 
	sudo make
	# Copy the library into the erlang's lib directory
	sudo cp -R /tmp/fast_xml /usr/local/lib/erlang/lib
}


install_mod_first_component () {

	# Include lager in the erlang's lib directory
	sudo cp -R /lib/lager* /usr/local/lib/erlang/lib

	# clone mod_first_component and install it
	# before the merge into the develop branch is done, copy the branch: 
	#git clone -b feature/G2-159-g2-component-startup-query-ejabbed ssh://git@scm.intamac.com:22/ejab/mod_first_component.git
	# Later on, just pull from the default:
	cd ~/.ejabberd-modules/sources
	if [ -d mod_first_component ]; then
		sudo rm -rf mod_first_component
	fi 
	git clone -b develop ssh://git@scm.intamac.com:22/ejab/mod_first_component.git
	#sudo mv /tmp/mod_first_component ~/.ejabberd-modules/sources
	# sudo ejabberdctl modules_update_specs
	cd ~/.ejabberd-modules/sources/mod_first_component/

	# Create an ebin directory for compiled beam files:
	mkdir -p ebin

	# Compile the module: 
	sudo erlc -I /lib/ejabberd*/include -pa /usr/local/lib/erlang/lager*/ebin -pa /usr/local/lib/erlang/lib/fast_xml/ebin -o ebin src/*
	echo mod_first_component modules compiled.

	# Create symlinks in ejabberd lib to the beams from the module:
	cd /lib/ejabberd*/ebin
	sudo ln -s /.ejabberd-modules/sources/mod_first_component/ebin/mod_first_component.beam 
	sudo ln -s /.ejabberd-modules/sources/mod_first_component/ebin/mod_first_component_utils.beam 
	echo Created symbolic links from ejabberd/ebin to mod_first_component beam files. 

	sudo ejabberdctl module_install mod_first_component 
	echo Installed mod_first_component. 	
}

