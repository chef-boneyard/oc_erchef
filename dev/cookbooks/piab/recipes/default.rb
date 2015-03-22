
# TODO bundle update in $root/oc/oc_erchef/dev
# to allow our project tooling to work without
# any steps
# NOTE: will need to REMOVE the vendor dir
# first, in case of an old run, or in case of
# ... ? user running on host without realizing?
# TODO we will want to build/isntall a system gecode?
# We add a few utility scripts for dev work into $HOME/bin

node['packages'].each do |p|
  package p
end

directory "/opt/users" do
  action :create
end
directory "/opt/orgs" do
  action :create
end

home = "/home/vagrant"
# Ensure the private chef bin/ dir is first in our PATH
path_elts = ["#{home}/bin",
             '/opt/opscode/embedded/bin',
             '/opt/opscode/bin',
             '/opt/chefdk/bin',
             '/opt/chefdk/embedded/bin',
             '/opt/opscode/embedded/jre/bin',
            '$PATH']
wanted_path = path_elts.join(':')
# TODO - this can be a template or file.
file "/etc/profile.d/omnibus-embedded.sh" do
  content <<EOF
# export DEVVM=1
export USE_SYSTEM_GECODE=1
# TODO will this be diffeerent for root vs user?
export PATH=#{wanted_path}
EOF
  action :create
end
# TODO - both home things for root and vagrant?
#
directory "#{home}/.ssh" do
  action :create
  owner "vagrant"
  group "vagrant"
  mode "0700"
end
template "#{home}/.ssh/ssh_config" do
  source "ssh_config"
  action :create
  owner "vagrant"
  user "vagrant"
  mode "600"
end

template "/etc/sudoers" do
  source "sudoers"
  action :create
  owner "root"
  user "root"
  mode 0440
end

directory "#{home}/bin" do
  action :create
  owner "vagrant"
  user "vagrant"
end

file "#{home}/.erlang" do
  content "code:load_abs(\"#{home}/bin/user_default\")."
  action :create
end

cookbook_file "user_default.erl" do
  path "#{home}/bin/user_default.erl"
  action :create_if_missing
  source "user_default.erl"
end

directory "/home/vagrant/bin" do
  action :create
  owner 'vagrant'
  group 'vagrant'
end

execute "set up user_default for erlang console use" do
  command "/opt/opscode/embedded/bin/erlc user_default.erl"
  cwd "#{home}/bin"
end
# TODO - kept this from original - looks like it may be useful?
template "/home/vagrant/bin/b2f" do
  source "b2f"
  mode "0777"
  action :create
end
#
# TODO MOTD with some useful instructions and available commands
# TODO our configure tool should be installed, configured with deps, and placed in the path.
