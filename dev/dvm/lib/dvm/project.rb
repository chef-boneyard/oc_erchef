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
    attr_reader :name, :project, :config, :deps, :source_path, :service

    def initialize(project_name, config)
      @name = project_name
      @config = config
      @project = config['projects'][project_name]
      @service = @project['service']
      @deps = []
      # TODO check required fields in config
    end
    def database
      raise "No database configured for #{name}" unless @config['database']
      @config['database']
    end


    def load(build = true)
    end

    def load_dep(name)

    end

    def unload

    end

    def update

    end

    def console
      raise "Unsupported"

    end
  end
  class ErlangProject < Project
    attr_reader :rebar_config_path, :project_dir, :relpath
    def initialize(project_name, config)
      super
      @project_dir = "/mnt/host/#{config['config']['source_path']}/#{project_name}"
      # TODO use lock or real?
      @rebar_config_path = "#{project_dir}/rebar.config"
      # TODO only bother with this if/when we need it
      eval(`./parse.es #{@rebar_config_path}`).each do |name, data|
        @deps << ProjectDep.new(name, "#{project_dir}/deps", data)
      end
      reldir = service['rel-type'] == 'relx' ? "_rel" : "rel"
      # TODO use the mounted location not source!
      @relpath = "#{@project_dir}/#{reldir}/#{name}"
    end
    def console
      exec "erl -name dvm@127.0.0.1 -remsh #{service["node"]} -setcookie #{service["cookie"]}"
    end
    def update
      puts "Kicking sync to pick up any updates..."
      cookie = service["cookie"]
      node = service["node"]
      `erl -hidden -name dvm@127.0.0.1 -setcookie #{cookie} -eval "rpc:call('#{node}', sync, go, [])." -s erlang halt`
      `erl -hidden -name dvm@127.0.0.1 -setcookie #{cookie} -eval "rpc:call('#{node}', sync, pause, [])." -s erlang halt`
    end

  end
  class RubyProject < Project

  end
  class CookbookProject < Project

  end
end
