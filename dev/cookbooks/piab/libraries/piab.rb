require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

class PiabHelper

  def self.omnibus_root
    "/opt/opscode"
  end

  def self.omnibus_bin_path
    self.omnibus_root + "/embedded/bin"
  end


  def self.existing_config
    if ::File.exists?("/etc/opscode/chef-server-running.json")
      return Chef::JSONCompat.from_json(IO.read(path))["private_chef"]
    end
    raise "no existing config found"
  end

end
