require "yaml"
require "pp"
data = YAML.load_file("defaults.yml")
if (File::exists? "config.yml")
  user = YAML.load_file("config.yml")
  data.merge(user)
end
# Next up, walk the hash and replace $source_path

