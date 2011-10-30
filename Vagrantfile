Vagrant::Config.run do |config|
  config.vm.box = "lucid32"

  config.vm.forward_port "http", 3000, 8300

  config.vm.provision :chef_solo do |chef|
     chef.log_level = :debug
     chef.cookbooks_path = "cookbooks"
     chef.roles_path = "roles"
     chef.add_role "pophealth"     
  end

end
