#!/bin/sh

# First let's update this repo
git pull

# Make sure our submodules are init'd.
# This really only matters the first time.
cd ../
git submodule init
git submodule update
cd basic-php

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

vagrant ssh -c"sudo FACTER_ec2_security_groups=webserver-httpd,db-mongo /usr/bin/puppet apply --verbose --modulepath /vagrant/aws-ec2-puppet/modules /vagrant/aws-ec2-puppet/manifests/nodes.pp" # Yet another puppet run
vagrant ssh -c"sudo FACTER_ec2_security_groups=webserver-httpd,db-mongo /usr/bin/puppet apply --verbose --modulepath /vagrant/aws-ec2-puppet/modules /vagrant/aws-ec2-puppet/manifests/nodes.pp" # Yet another puppet run

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

vagrant ssh -c'sudo chkconfig nginx off'
vagrant ssh -c'mkdir -p /vagrant/htdocs'
vagrant ssh -c'sudo /sbin/service nginx stop'
vagrant ssh -c'sudo yum install -y php'
vagrant ssh -c'cd /etc/httpd/conf.d/; sudo ln -s /vagrant/simple-site.conf .'
vagrant ssh -c'mkdir -p /vagrant/htdocs'
vagrant ssh -c'sudo /sbin/service httpd restart'
