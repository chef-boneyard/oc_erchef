require "mixlib/shellout"

module DVM
  class ProjectDep
    attr_reader :name, :ref, :url, :path
    def initialize(name, base_dir, data)
      @url = data["url"]
      @ref  = data["ref"]
      @name = name
      @path = "#{base_dir}/#{name}"
    end
    def loaded?
      File.symlink? path
    end
    def load
    end
    def unload
      # erlang rpojects we need rebar get-dep to bring it back
      # unless we want to do the preserve dance.
    end
  end
  class Project
    attr_reader :name, :project, :config, :source_path, :service

    # TODO check required fields in config
    def initialize(project_name, config)
      @name = project_name
      @config = config
      @project = config['projects'][project_name]
      @service = @project['service']
      @deps = []
    end
    def database
      raise ArgumentError, "No database configured for #{name}" unless @project['database']
      @project['database']
    end

    def deps
      parse_deps
    end

    def load(build)

    #  parse_deps
    end

    def loaded?
      false
    end

    def load_dep(name, build)
      # TODO separate impl so we can ensure parse_deps and "loaded?"
      raise ArgumentError, "This application does not support loading dependencies."
    end

    def unload
      raise "You should implement this now."
    end

    def update
      raise ArgumentError, "This application does not support dynamic updates."
    end

    def console
      raise ArgumentError, "This application does not support a console."
    end
    def parse_deps
      @deps = {}
    end
  end


  class ErlangProject < Project
    attr_reader :rebar_config_path, :project_dir, :relpath
    def initialize(project_name, config)
      super
      @project_dir = "/mnt/host/#{config['config']['source_path']}/#{project_name}"
      # TODO use .lock if available, else use .config
      @rebar_config_path = "#{project_dir}/rebar.config.lock"
      reldir = service['rel-type'] == 'relx' ? "_rel" : "rel"
      @relpath = "#{@project_dir}/#{reldir}/#{name}"
      @service_dir = "/var/opt/opscode/embedded/service/#{service['name']}"
    end
    def parse_deps
      path = File.expand_path("../../parse.es", __FILE__)
      eval(`#{path} #{@rebar_config_path}`).each do |name, data|
        @deps << ProjectDep.new(name, "#{project_dir}/deps", data)
      end
    end
    def console
      exec "#{erl_command} -remsh #{service["node"]}"
    end
    def loaded?
      mounts = `mount`
      mounts.split("\n").each do |mount|
        if mount.include? @service_dir
          return true
        end
      end
      false
    end
    def unload_dep(name)

    end
    def unload_dep(name)

      # update
    end

    def load_dep(name, build)
      raise ArgumentError, "Load the project before loading deps." unless loaded?
      # update
    end

    def load(no_build = false)
      raise ArgumentError, "Project already loaded" if loaded?
      do_build unless no_build
      say("Stopping #{service['name']}")
      `chef-server-ctl stop #{service['name']}`
      say("Setting up symlinks")
      FileUtils.rm_rf(["#{relpath}/log", "#{relpath}/sys.config"])
      FileUtils.ln_s("/var/opt/opscode/#{service["name"]}/sys.config", "#{relpath}/sys.config")
      FileUtils.ln_s("/var/log/opscode/#{service["name"]}", "#{relpath}/log")

      say("Bind mounting release into service dir")
      cmd = Mixlib::ShellOut.new("mount -o bind #{relpath} /opt/opscode/embedded/service/#{service["name"]}")
      cmd.run_command
      cmd.error!

      say(HighLine.color("Success! Your project is loaded.", :green))
      say("Start it now with:")
      say("   cd #{relpath}")
      say("   bin/#{name} console")
      say("Or use:")
      say("   bin/#{name} start")
      # TODO auto start? or tell user to? option?
    end

    def do_build
      # TODO we're effectively refreshing deps here -
      # should we reload our tracking of them?
      #
      ## TODO can we be smarter - check for library
      #links that contain /mnt/home anywhere inthem? that implies
      #devrel already done on this vm.
      say("Cleaning deps...")
      FileUtils.rm_rf(["#{project_dir}/deps"])

      say("Cleaning up everything else...")
      cmd = Mixlib::ShellOut.new("make clean relclean", :cwd => project_dir)
      cmd.run_command
      cmd.error!


      say("Getting all deps, please hold.")
      cmd = Mixlib::ShellOut.new("rebar get-deps", :cwd => project_dir)
      cmd.run_command
      cmd.error!

      say("Building.  This will take a few.")
      say(HighLine.color("Might I suggest taking this time contemplate the the awesome development journey you're about to embark upon.", :cyan))
      cmd = Mixlib::ShellOut.new("make -j 8 devrel", :cwd => project_dir,
                                                     :env => { "USE_SYSTEM_GECODE" => "1"})
      cmd.run_command
      cmd.error!

    end

    def update
      puts "alerting sync to pick up any updates..."
      node = service["node"]
      `#{erl_command} -eval "rpc:call('#{node}', sync, go, [])." -s erlang halt`
      `#{erl_command} -eval "rpc:call('#{node}', sync, pause, [])." -s erlang halt`
    end

    def erl_command
      "erl -hidden -name dvm@127.0.0.1 -setcookkie #{service["cookie"]}"
    end

  end


  class RubyProject < Project

  end


  class CookbookProject < Project

  end
end
