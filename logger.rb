#!/usr/bin/env ruby

$: << File.join(File.dirname(__FILE__), 'lib')

require 'irclogger'
require 'irclogger/cinch_plugin'
require 'redis'
require 'daemons'

IrcLogger::CinchPlugin.redis = Redis.new(url: Config['redis'])

pidfile = File.join(File.dirname(__FILE__), 'tmp', 'logger.pid')
logfile = File.join(File.dirname(__FILE__), 'log', 'logger.log')

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

    # Auth config
    c.user     = Config['username']
    c.password = Config['password'] unless Config['password'].nil?
    c.realname = Config['realname']
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

# Who logs the loggers?
bot.loggers.level = :info

DB.disconnect
Daemonize.daemonize(logfile)

File.open(pidfile, 'w') do |f|
  f.write Process.pid
end

bot.start
