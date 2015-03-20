class DVM
  def self.hi
    puts "hi"
  end
end
# Some usage ideas
# dvm load oc_erchef --restart-service
# dvm load oc_erchef chef_authn --restart-service
# dvm update oc_erchef ? monitoringrequired.
# dvm unload oc_erchef chef_authn
# dvm unload oc_erchef
# dvm load omnibus-cookbooks --reconfigure
# dvm load omnibus-X? anything else we care about?
# dvm console oc_erchef -- detects if runng and attaches, or starts it appropriately.
# dvm etop oc_erchef --
# dvm unload
#
#
# PATH - root is set to /opt/opscode/embedded/bin -
#        vagrant is set to chefdk?
#
# Steps: make devrel
# preserve: log dirs, config file.
# Don't forget root needs user_defaults too!
# TODO - with sync support automatic - some kind of env var check in supervisor?
#mnt/host/oc/oc_erchef/_rel/oc_erchef# ln -s /var/log/opscode/opscode-erchef log
# HOME HOME=/var/opt/opscode/opscode-erchef _rel/oc_erchef/bin/oc_erchef console
# ^ home means we don't have to symlink config?!
#
#

# dvm load
# dvm load project [depname] - latter implies former?
# dvm unload project
#
# Erlang projects:
# dvm projects -> lists stuff in service dir, and if it's loaded?
# dvm update project - instead of leaving sync sucking up cycles, can we instead just do it on demand ?
# dvm console - attach or start and attach
# dvm etop
