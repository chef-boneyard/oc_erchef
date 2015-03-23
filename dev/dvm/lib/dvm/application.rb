 # Interesting to note that thor and highliine are already in our
# omnibus bundle.
require "thor"
require "highline/import"
require "deep_merge"
require "yaml"

module DVM
  PROJECT_CLASSES = {
    "cookbook" => DVM::CookbookProject,
    "erlang" => DVM::ErlangProject,
    "ruby" => DVM::RubyProject
  }
  class Application < Thor
    def initialize(args, local_options,config)
      super

      @projects = {}
      # Note use of hard-coded paths here.  Since I want this installed
      # as a gem, and to accept modifications at any time to the config files,
      # and this is intended for use ina  controlled environment - this seems
      # like the best answer.
      @config = YAML.load_file("/vagrant/defaults.yml")
      if File.file? "/vagrant/config.yml"
        overrides = YAML.load_file("/vagrant/config.yml")
        @config.deep_merge! overrides
      end
      @config["projects"].each do |name, project|
        type = project["type"]
        @projects[name] = PROJECT_CLASSES[type].new(name, @config)
      end
    end


    desc "list [project]", "list available projects, or available dependencies within project"
    def list(project = nil)
      if project == nil
        @projects.each do |name, p|
          say("#{HighLine.color(name, :green)}")
          deps = p.deps.keys
          say(" Loadable deps: #{deps.join(" ")}") if deps.length > 0
        end
      else
        say(highline.color("#{project} deps:", :bold))
        project = @projects[project]
        project.deps.each do |dep|
          status, c = dep.loaded? ? ["loaded", :green] : ["available", :white]
          say("  #{dep.name}: #{highline.color(status, c)}")
        end
      end
    end

    option :"no-build", type: :boolean,
                        aliases: ['-n'],
                        desc: "skip the build phase and just load/mount the source path"
    desc "load <project> [dep]", "load a project or project's named dependency"
    def load(project_name, dep = nil)
      ensure_project(project_name)
      if dep.nil?
        @projects[project_name].load(options[:build])
      else
        @projects[project_name].load_dep(dep, options[:build])
      end
    end


    desc "etop <project>", "run etop to monitor the running project"
    def etop(project_name)
      ensure_project(project_name)
    end

    desc "update <project>",  "if the  project supports it, apply any updates to a running instance"
    def update(project_name)
      ensure_project(project_name)
      @projects[project_name].update
    end

    desc "console <project>", "connect to a running process in a console if the projects upports it. Start the process if necessary"
    def console(project_name)
      ensure_project(project_name)
      @projects[project_name].console
    end

    desc "psql <project>", "connect to the database for a project, if it exists"
    def psql(project_name)
      ensure_project(project_name)
      database = @projects[project_name].database
      exec "sudo -u opscode-pgsql /opt/opscode/embedded/bin/psql #{database}"
    end

  private

  def ensure_project(name)
    raise ArgumentException, "No such project: #{name}" unless @projects.has_key?(name)
  end

  def highline
    @highline ||= begin
      require 'highline'
      HighLine.new
    end
  end

  end

end
