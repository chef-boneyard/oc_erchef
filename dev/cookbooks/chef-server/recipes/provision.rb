installer_path = node['chef-server']['installer_path']

# Bare minimum packages for other stuff to work:
package "build-essential"
package "git"

# And now chef server installer:
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

template "/etc/hosts" do
  source "hosts.erb"
  owner "root"
  group "root"
  action :create
  variables({"fqdns" => ["api.chef-server.dev",  "manage.chef-server.dev" ]})
end

execute "reconfigure" do
  command "chef-server-ctl reconfigure"
  action :nothing
end

