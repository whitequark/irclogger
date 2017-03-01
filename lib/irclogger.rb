require 'logger'
require 'yaml'
require 'sequel'

Config = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'config', 'application.yml'))
DB     = Sequel.connect(Config['database'], :encoding => Config['database'].start_with?('mysql') ? 'utf8mb4' : 'utf8')

require 'irclogger/message'
require 'irclogger/channel'