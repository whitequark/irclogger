$: << File.join(File.dirname(__FILE__), 'lib')

require 'thin'
require 'irclogger/config'

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

if Config['web'].include? ':'
  host, port = Config['web'].split(':')
  server_args = [host, port.to_i]
else
  server_args = [File.join(Config['files']['tmp'], Config['web'])]
end

server = Thin::Server.new(*server_args)
server.maximum_connections = 1024
server.maximum_persistent_connections = 256
server.log_file = File.join(Config['files']['log'], 'viewer.log')
server.pid_file = File.join(Config['files']['tmp'], 'viewer.pid')
server.daemonize
server.reopen_log
server.app = Rack::Builder.new do
  require 'irclogger'
  require 'irclogger/viewer'

  IrcLogger::Channel.listen

  run IrcLogger::Viewer
end.to_app
server.start
