#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'irclogger'

pidfile    = File.join(Config['files']['tmp'], 'logger.pid')
executable = File.join(File.dirname(__FILE__), 'logger.rb')

timeout = 180
respawn = true
if Config.include?("watchdog")
  timeout = Config["watchdog"]["timeout"]
  respawn = Config["watchdog"]["respawn"]
end

unless Message.any_recent_messages?(timeout)
  verb = respawn ? "restarting" : "terminating"
  puts "irclogger is stale, #{verb}"

  begin
    pid = File.read(pidfile).to_i
    Process.kill(:TERM, pid)
  rescue Errno::EPERM, Errno::ESRCH => e
    puts "cannot kill: #{e.message}"
  end

  if respawn
    Process.spawn(executable)
  end
end
