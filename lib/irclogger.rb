require 'logger'
require 'yaml'
require 'sequel'

root_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
Config = YAML.load_file(ENV["IRCLOGGER_CONFIG"] || File.join(root_dir, 'config', 'application.yml'))
Config['files'] = {
    'log' => File.expand_path(Config['files']['log'], root_dir),
    'tmp' => File.expand_path(Config['files']['tmp'], root_dir),
}

db_encoding = Config['database'].start_with?('mysql') ? 'utf8mb4' : 'utf8'
DB = Sequel.connect(Config['database'], :encoding => db_encoding).extension(:auto_literal_strings)

require 'irclogger/message'
require 'irclogger/channel'
