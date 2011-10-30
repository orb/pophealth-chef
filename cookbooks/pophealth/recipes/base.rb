###### CORE REQUIREMENTS

# make sure everything is current
include_recipe "apt"

include_recipe "rvm::ruby_192"

%w(git-core redis-server mongodb).each do |pkg|
    package pkg do
        action :upgrade
    end
end


