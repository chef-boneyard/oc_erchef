

node['packages'].each do |p|
  package p
end
directory "/opt/users" do
  action :create
end
directory "/opt/orgs" do
  action :create
end

# We add a few utility scripts for dev work into $HOME/bin
directory "/home/vagrant/bin" do
  action :create
  owner 'vagrant'
  group 'vagrant'
end

template "/home/vagrant/bin/b2f" do
  source "b2f"
  mode "0777"
  action :create
end

# Ensure the private chef bin/ dir is first in our PATH
path_elts = ['$HOME/bin',
             "#{PiabHelper.omnibus_root}/embedded/bin",
             "#{PiabHelper.omnibus_root}/embedded/jre/bin",
            '$PATH']
wanted_path = path_elts.join(':')
file "/etc/profile.d/omnibus-embedded.sh" do
  content "export PATH=\"#{wanted_path}\""
  action :create
end

template "#{ENV['HOME']}/.ssh/ssh_config" do
  source "ssh_config"
  action :create
  owner "vagrant"
  user "vagrant"
  mode "0600"
end

template "/etc/sudoers" do
  source "sudoers"
  action :create
  owner "root"
  user "root"
  mode 0440
end


home = ENV['HOME']

file "#{home}/.erlang" do
  content "code:load_abs(\"#{home}/bin/user_default\")"
  action :create
end

cookbook_file "user_defaults.erl" do
  path "#{home}/bin/user_defaults.erl"
  action :create_if_missing
  source "user_defaults.erl"
end

execute "set up user_defaults for erlang console use" do
  command "/opt/opscode/embedded/bin/erlc user_defaults.erl"
  cwd "#{ENV['HOME']}/bin"
end

