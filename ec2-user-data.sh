#!/bin/bash
# inspired by http://allanfeid.com/content/using-amazons-cloudformation-cloud-init-chef-and-fog-automate-infrastructure
log='/tmp/init.log'
apt-get update &>> $log
apt-get install -y ruby ruby1.8-dev build-essential wget libruby-extras libruby1.8-extras git-core &>> $log
cd /tmp
wget http://production.cf.rubygems.org/rubygems/rubygems-1.3.7.tgz &>> $log
tar zxf rubygems-1.3.7.tgz &>> $log
cd rubygems-1.3.7
ruby setup.rb --no-format-executable &>> $log
gem install ohai chef --no-rdoc --no-ri --verbose &>> $log

mkdir -p /var/chef/cache
mkdir -p /opt/pophealth-chef
git clone https://github.com/orb/pophealth-chef.git /opt/pophealth-chef &>> $log
ln -s /opt/pophealth-chef/cookbooks /var/chef/cookbooks
ln -s /opt/pophealth-chef/roles /var/chef/roles 
mkdir /etc/chef

cat <<EOF > /etc/chef/solo.rb
file_cache_path "/var/chef/cache"
cookbook_path "/var/chef/cookbooks"
role_path "/var/chef/roles"
json_attribs "/etc/chef/node.json"
log_location "/var/chef/solo.log"
verbose_logging true
EOF

cat <<EOF > /etc/chef/node.json
{
  "run_list": [ 
    "role[pophealth]"
  ]
}
EOF

chef-solo &>> $log

