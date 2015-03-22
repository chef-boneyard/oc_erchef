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
#

#

# dvm load
# dvm load project [depname] - latter implies former?
# dvm unload project

# dvm psql
#
def psql(database)
  exec "sudo -u opscode-pgsql /opt/opscode/embedded/bin/psql #{database}"
end
#def test(focii)

#end
#
# dvm remsh
def start(app)
  `chef-server-ctl start #{project['app']['service-name']}`
end

def start!(app)
  `chef-server-ctl start #{project['app']['service-name']}`
end

def remsh!(cookie, node)
  # Exec will replace the ruby proc with the one we're spawning, which is exactly what we want.
  exec  "erl -hidden -name dvm@127.0.0.1 -setcookie #{cookie} -remsh #{node}"
end
def etop!(cookie, node)
  # Exec will replace the ruby proc with the one we're spawning, which is exactly what we want.
  exec  "erl -hidden -name dvm@127.0.0.1 -setcookie #{cookie} -remsh #{node}"
end

def update_via_sync(cookie, node)
  # sync currently has a problem where it sucks up massive amounts of CPU,so we can't leave it running.
  # Instead, we'll tell it to start up then immediately stop it. This will still have kicked off the sync process
  # for updates, and stop it from starting any more at intervals. Because messags will arrive sequentially
  # there is no chance of a race condition
  `erl -hidden -name dvm@127.0.0.1 -setcookie #{cookie} -eval "rpc:call('#{node}', sync, go, [])." -s erlang halt`
  `erl -hidden -name dvm@127.0.0.1 -setcookie #{cookie} -eval "rpc:call('#{node}', sync, pause, [])." -s erlang halt`
end


# Erlang projects:
# dvm projects -> lists stuff in service dir, and if it's loaded?
# dvm update project - instead of leaving sync sucking up cycles, can we instead just do it on demand
# dvm console - attach or start and attach
# dvm etop
