
case node['platform']
when "ubuntu"
  include_recipe "apt"

  package "drbd8-utils" do
    action :install
  end
when "centos"
  include_recipe "yum"

  yum_key "RPM-GPG-KEY-elrepo" do
    url "http://elrepo.org/RPM-GPG-KEY-elrepo.org"
    action :add
  end

  remote_file "/tmp/elrepo.rpm" do
    case node['platform_version']
    when /^6/
      source "http://elrepo.org/elrepo-release-6-5.el6.elrepo.noarch.rpm"
    when /^5/
      source "http://elrepo.org/elrepo-release-5-4.el5.elrepo.noarch.rpm"
    end
  end

  rpm_package "elrepo" do
    source "/tmp/elrepo.rpm"
  end

  package "drbd84-utils" do
    action :install
    case node['platform_version']
    when "6.4"
      version "8.4.4-2.el6.elrepo"
    when "6.3"
      version "8.4.2-1.el6.elrepo"
    when /^6\.[012]/
      version "8.4.1-2.el6.elrepo"
    when /^5/
      version nil
    end
  end

  package "kmod-drbd84" do
    action :install
    case node['platform_version']
    when "6.4"
      version "8.4.4-1.el6.elrepo"
    when "6.3"
      version "8.4.2-1.el6_3.elrepo"
    when /^6\.[012]/
      version "8.4.1-2.el6.elrepo"
    when /^5/
      version nil
    end
  end
end

execute "pvcreate /dev/sdb" do
  action :run
end

execute "vgcreate opscode /dev/sdb" do
  action :run
end

execute "lvcreate -L 9G -n drbd opscode" do
  action :run
end
