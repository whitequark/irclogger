require 'sequel'
require 'logger'

Config = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'config', 'application.yml'))
DB = Sequel.connect(Config['database'])

require 'irclogger/message'
