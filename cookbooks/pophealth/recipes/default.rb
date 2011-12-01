include_recipe "pophealth::base"

####### USERS

group "pophealth" do
    gid 600
end

user "pophealth" do
    home "/opt/pophealth/"
    shell "/bin/bash"
    uid 600
    gid "pophealth"
end

execute "pophealth_rvmgroup" do
    command "usermod -G rvm -g pophealth pophealth"
end

bash "pop_bundle" do
    user "pophealth"
    group "rvm"

    code <<-EOH
        source /etc/profile.d/rvm.sh
        rvm use 1.9.2@pophealth --create
        gem install bundler
        rvm wrapper 1.9.2@pophealth pop bundle
    EOH
end


# ###### APP 

%w(/opt/pophealth /opt/pophealth/deploy/ /opt/pophealth/deploy/shared /opt/pophealth/deploy/shared/log /opt/pophealth/deploy/shared/pids).each do |dir|
    directory dir do
        owner "pophealth"
        group "pophealth"
        mode "0755"
        action :create
        recursive true
    end
end

git "/opt/pophealth/measures" do
    user "pophealth"
    group "pophealth"

    repository "git://github.com/pophealth/measures.git"
    #repository "/vagrant/repos/measures"
    reference "master"
    action :sync
    notifies :run, "bash[install_measures]", :immediately
end

bash "install_measures" do
    user "pophealth"
    group "rvm"

    cwd "/opt/pophealth/measures/"
    code <<-EOH
        source /etc/profile.d/rvm.sh
        rvm use 1.9.2@pophealth --create
        bundle install
    EOH
    # action :nothing
end

template "/etc/init/pophealth.conf" do
    mode "0755"
    source "pophealth.conf.erb"
end

link "/etc/init.d/pophealth" do
  to "/lib/init/upstart-job"
end

template "/etc/init/pophealth-queue.conf" do
    mode "0755"
    source "pophealth-queue.conf.erb"
end

link "/etc/init.d/pophealth-queue" do
  to "/lib/init/upstart-job"
end

deploy_revision "/opt/pophealth/deploy" do
    scm_provider Chef::Provider::Git
    repository "git://github.com/pophealth/popHealth.git"
    revision "master"

    user "pophealth"
    group "pophealth"

    before_migrate do
        bash "pophealth dependecies" do
           user "pophealth"
           group "rvm"
           cwd release_path
           code <<-EOH
               source /etc/profile.d/rvm.sh
               rvm use 1.9.2@pophealth --create
               bundle install
           EOH
        end
    end

    action :deploy
    notifies :restart, "service[pophealth]"
    notifies :restart, "service[pophealth-queue]"
end

bash "pophealth admin" do
    user "pophealth"
    group "rvm"
    cwd "/opt/pophealth/deploy/current"
    code <<-EOH
        source /etc/profile.d/rvm.sh
        rvm use 1.9.2@pophealth --create
        ruby -e 'puts File.expand_path("~")'
        bundle exec rake admin:create_admin_account --trace
    EOH

    not_if 'mongo pophealth-development --eval "printjson(db.getCollectionNames())" | grep users'
    action :run
end


service "pophealth" do
    provider Chef::Provider::Service::Upstart
    supports :status => true, :start => true, :stop => true, :restart => true
    action [:start, :enable]
end

service "pophealth-queue" do
    provider Chef::Provider::Service::Upstart
    supports :status => true, :start => true, :stop => true, :restart => true
    action [:start, :enable]
end
