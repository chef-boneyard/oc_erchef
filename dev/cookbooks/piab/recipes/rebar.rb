
unless ::File.exists?("#{PiabHelper.omnibus_root}/embedded/bin/rebar")

  erlang_path = "#{PiabHelper.omnibus_root}/embedded/lib/erlang"

  git "#{Chef::Config[:file_cache_path]}/rebar" do
    repository "https://github.com/rebar/rebar.git"
    revision "2.0.0"
    depth 1
    notifies :run, "execute[compile and install rebar]", :immediately
  end

  execute "compile and install rebar" do
    command <<-CODE
  ./bootstrap
  cp ./rebar #{erlang_path}/bin/
  CODE
    cwd "#{Chef::Config[:file_cache_path]}/rebar"
    environment(
      'PATH' => "#{erlang_path}/bin:#{ENV['PATH']}"
    )
    creates "#{erlang_path}/bin/rebar"
  end

  # set the correct perms
  file "#{erlang_path}/bin/rebar" do
    mode "0755"
  end

  # symlink over into /opt/opscode/embedded/bin
  link "#{PiabHelper.omnibus_root}/embedded/bin/rebar" do
    to "#{erlang_path}/bin/rebar"
  end

end
