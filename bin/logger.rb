#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'irclogger'
require 'irclogger/cinch_plugin'
require 'irclogger/cinch_compat'
require 'redis'
require 'daemons'

IrcLogger::CinchPlugin.redis = Redis.new(url: Config['redis'])

pidfile = File.join(Config['files']['tmp'], 'logger.pid')
logfile = File.join(Config['files']['log'], 'logger.log')

begin
  old_pid = File.read(pidfile).to_i
  Process.kill 0, old_pid

  raise "An existing logger process is running with pid #{old_pid}. Refusing to start"
rescue Errno::ESRCH, Errno::ENOENT
end

bot = Cinch::Bot.new do
  configure do |c|
    # Server config
    c.server   = Config['server']
    c.port     = Config['port'] unless Config['port'].nil?
    c.ssl.use  = Config['ssl'] unless Config['ssl'].nil?
    c.ssl.verify = Config['ssl_verify'] unless Config['ssl_verify'].nil?

    # Auth config
    c.user     = Config['username']
    c.password = Config['password'] unless Config['password'].nil?
    c.realname = Config['realname']
    if Config['sasl']
      c.sasl.username = Config['username']
      c.sasl.password = Config['password']
    end
    c.nicks    = [Config['nickname']]
    c.nick     = Config['nickname']

    # Logging config
    c.channels = Config['channels']

    # cinch, oh god why?!
    c.plugins.plugins = [IrcLogger::CinchPlugin]

    # Trying to avoid "Excess Flood"
    c.messages_per_second = 0.4

  end
end

File.open(pidfile, 'w') do |f|
  f.write Process.pid
end

# Who logs the loggers?
bot.loggers = Cinch::Logger::FormattedLogger.new(File.open(logfile, 'a'))
bot.loggers.level = :info

if Config['daemonize']
  DB.disconnect
  Daemonize.daemonize
end

bot.start
