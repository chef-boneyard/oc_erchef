# create dir chef-shell.rb for pivotal user, configured to operate at server root across orgs.
# This isn't for knife itself, but for testing and debugging direct REST API calls via chef-shell,
# where those calls are fully qualified with an org name.
# Note that we are copying the pivotal pem here so that it's avalalbe from outside the vm.

user_root = "/srv/piab/users"
directory "#{user_root}/pivotal/.chef" do
  recursive true
  action :create
end

file "#{user_root}/pivotal/.chef/pivotal.pem" do
  action :create
  content ::File.open("/etc/opscode/pivotal.pem").read
end

template "#{user_root}/pivotal/.chef/chef-shell.rb" do
  source "chef-shell.rb.erb"
  variables(
    :server_fqdn => 'api.opscode.piab'
  )
  mode "0777"
  action :create
end

