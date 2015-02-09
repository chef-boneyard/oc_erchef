#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
#
# All Rights Reserved

installer_path = node['chef-server']['installer_path']
package File.basename(installer_path) do
  source installer_path
  provider Chef::Provider::Package::Dpkg
  action :install
  not_if { File.exists? "/opt/opscode/bin/chef-server-ctl" }
end

# configure

directory "/etc/opscode" do
  owner "root"
  group "root"
  recursive true
  action :create
end

template "/etc/opscode/chef-server.rb" do
  source "chef-server.rb.erb"
  owner "root"
  group "root"
  action :create
  notifies :run, "execute[reconfigure]", :immediately
end

execute "reconfigure" do
  command "chef-server-ctl reconfigure"
  action :nothing
  not_if { node['private-chef']['topology'] =~ /ha/ }
end

# ensure the node can resolve the FQDNs locally
[ "api.chef-server.dev",
  "manage.chef-server.dev"].each do |fqdn|

  execute "echo 127.0.0.1 #{fqdn} >> /etc/hosts" do
    not_if "host #{fqdn}" # host resolves
    not_if "grep -q #{fqdn} /etc/hosts" # entry exists
  end
end
