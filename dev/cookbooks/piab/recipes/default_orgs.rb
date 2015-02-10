user_root = "/opt/users"
org_root = "/opt/orgs"
# knife ssl fetch
# knife client create node1  -s https://api.chef-server.dev/organizations/myorg -k myorg.pem -u myorg-validator -d > ..nodes/node1/.chef/node1.pem
# knife node create node1     -s https://api.chef-server.dev/organizations/myorg -k myorg.pem -u myorg-validator -d

organizations = node['organizations']
organizations.each do |org|
  orgname = org['orgname']
  org_validator = "#{org_root}/#{orgname}-validator.pem"
  execute "create organization #{orgname}" do
    command "chef-server-ctl org-create #{orgname} #{orgname} > #{org_validator}"
    not_if "chef-server-ctl show-org | grep -e ^#{orgname}:"
  end
  org["nodes"].each do |nodename|
    dot_chef = "#{org_root}/#{nodename}/.chef"
    private_key = "#{user_root}/#{nodename}.pem"
    directory dot_chef do
      action :create
      recursive true
    end
    execute "ssl-fetch" do
      command "knife ssl fetch"
    end
    # TODO knife in path?
    # TODO pivotal or just use validator?
    execute "create client #{nodename}" do
      command "knife client create #{nodename} -u #{orgname}-validator -k #{org_validator} -s https://api.erchef.dev > #{node_key_path}"
    end
    execute "create node #{nodename}" do
      # username first-name last-name email password
      command "knife node create #{nodename} -u #{nodename} -k #{node_key_path} -s https://api.erchef.dev
    end

  end
  org["users"].each do |username|
    dot_chef = "#{user_root}/#{username}/.chef"
    private_key = "#{user_root}/#{username}.pem"

    directory dot_chef do
      recursive true
      action :create
    end

    execute "create user #{username}" do
      # username first-name last-name email password
      command "chef-server-ctl user-create #{username} #{username} #{org['last_name']} #{username}@#{orgname}.com password > #{private_key}"
    end

    execute "associate #{username} with #{orgname}" do
      command "chef-server-ctl org-user-add #{orgname} #{username} --admin"
    end

    template "#{dot_chef}/knife.rb" do
      source "knife.rb.erb"
      variables(
        :username => username,
        :orgname => orgname,
        :server_fqdn => 'api.erchef.dev'
      )
      mode "0777"
      action :create
    end
  end
end
