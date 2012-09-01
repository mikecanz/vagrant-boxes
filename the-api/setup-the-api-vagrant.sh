#!/bin/sh

# First let's update this repo
git pull

# Make sure our submodules are init'd.
# This really only matters the first time.
cd ../
git submodule init
git submodule update
cd the-api

# Then we need to update the puppet repo
cd aws-ec2-puppet
git fetch origin
git checkout origin/master
cd ..

username=`git config user.name`
if [[ $username = "" ]]; then
    read -p "Enter your git commit name:" username
fi

useremail=`git config user.email`
if [[ $useremail = "" ]]; then
    read -p "Enter your git commit email:" useremail
fi

# Now vagrant can do it's thing.
vagrant up
vagrant reload

vagrant ssh -c"sudo FACTER_ec2_security_groups=webserver-nginx,db-mongo /usr/bin/puppet apply --verbose --modulepath /vagrant/aws-ec2-puppet/modules /vagrant/aws-ec2-puppet/manifests/nodes.pp" # Yet another puppet run
vagrant ssh -c"sudo FACTER_ec2_security_groups=webserver-nginx,db-mongo /usr/bin/puppet apply --verbose --modulepath /vagrant/aws-ec2-puppet/modules /vagrant/aws-ec2-puppet/manifests/nodes.pp" # Yet another puppet run

####################################################################################
# If you have private repos setup somewhere you can put your keys and hosts
# here so and uncomment the section below so they can be cloned automatically later.
####################################################################################
#known_hosts='<PUT YOUR KNOWN HOSTS HERE IF YOU WANT THAT SETUP AUTOMATICALLY>'
#id_rsa='<PUT YOUR PRIVATE KEY HERE IF YOU WANT THAT SETUP AUTOMATICALLY>'
#id_rsa_pub='<PUT YOUR PUBLIC KEY HERE IF YOU WANT THAT SETUP AUTOMATICALLY>'
#vagrant ssh -c"echo '$known_hosts' > ~/.ssh/known_hosts"
#vagrant ssh -c"echo '$id_rsa' > ~/.ssh/id_rsa"
#vagrant ssh -c"chmod 600 ~/.ssh/id_rsa"
#vagrant ssh -c"echo '$id_rsa_pub' > ~/.ssh/id_rsa.pub"
#vagrant ssh -c"chmod 744 ~/.ssh/id_rsa.pub"

vagrant ssh -c"git config --global user.name \"$username\""
vagrant ssh -c"git config --global user.email \"$useremail\""
vagrant ssh -c"git config --global color.ui \"auto\""

vagrant ssh -c'sudo install -g vagrant -o vagrant -d /home/ec2-user'
vagrant ssh -c'cd /home/ec2-user; git clone https://github.com/mikecanz/the-api.git'
vagrant ssh -c'cd /etc/nginx/conf.d/; sudo ln -s /home/ec2-user/the-api/etc/nginx/conf.d/the-api.conf .'
vagrant ssh -c'mkdir -p /home/ec2-user/the-api/logs'
vagrant ssh -c'/home/ec2-user/the-api/script/restart-dev.sh'
