#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
$: << File.join(File.dirname(__FILE__), 'lib')

require 'irclogger'

pidfile    = File.join(File.dirname(__FILE__), 'tmp', 'logger.pid')
executable = File.join(File.dirname(__FILE__), 'launch-logger.sh')

unless Message.any_recent_messages?
  puts "irclogger is stale, restarting"

  begin
    pid = File.read(pidfile).to_i
    Process.kill(:TERM, pid)
  rescue Errno::EPERM, Errno::ESRCH => e
    puts "cannot kill: #{e.message}"
  end

  Process.spawn(executable)
end