#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'thin'
require 'irclogger'
require 'irclogger/viewer'

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

if Config['web'].include? ':'
  host, _, port = Config['web'].rpartition(':')
  server_args = [host, port.to_i]
else
  server_args = [File.expand_path(Config['web'], Config['files']['tmp'])]
end

server = Thin::Server.new(*server_args) do
  DB.disconnect
  IrcLogger::Channel.listen
  run IrcLogger::Viewer
end
server.maximum_connections = 1024
server.maximum_persistent_connections = 256
server.pid_file = File.join(Config['files']['tmp'], 'viewer.pid')
server.log_file = File.join(Config['files']['log'], 'viewer.log')
server.reopen_log

if Config['daemonize']
  server.daemonize
end

server.start
