require 'yaml'

root_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
Config = YAML.load_file(ENV["IRCLOGGER_CONFIG"] || File.join(root_dir, 'config', 'application.yml'))
Config['files'] = {
    'log' => File.expand_path(Config['files']['log'], root_dir),
    'tmp' => File.expand_path(Config['files']['tmp'], root_dir),
}
