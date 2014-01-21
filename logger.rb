#!/usr/bin/env ruby

$: << File.join(File.dirname(__FILE__), 'lib')

require 'irclogger'
require 'irclogger/cinch_plugin'
require 'redis'

pidfile = File.join(File.dirname(__FILE__), 'tmp', 'logger.pid')

begin
  old_pid = File.read(pidfile).to_i
  Process.kill 0, old_pid

  raise "An existing logger process is running with pid #{old_pid}. Refusing to start"
rescue Errno::ESRCH, Errno::ENOENT
end

File.open(pidfile, 'w') do |f|
  f.write Process.pid
end

bot = Cinch::Bot.new do
  configure do |c|
    c.server   = Config['server']
    c.port     = Config['port'] if Config['port']
    c.channels = Config['channels']
    c.user     = Config['username']
    c.nick     = Config['nickname']
    c.realname = Config['realname']

    # cinch, oh god why?!
    c.plugins.plugins = [IrcLogger::CinchPlugin]
  end
end

IrcLogger::CinchPlugin.redis = Redis.new(url: Config['redis'])

bot.start
