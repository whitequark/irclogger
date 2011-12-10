#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
$: << File.join(File.dirname(__FILE__), 'lib')

require 'irclogger'
require 'net/yail'

def log(type, event, what=nil)
  case type
    when :system
      Message.create(:channel => event.channel, :timestamp => Time.now,
                      :line => what)
    when :message
      Message.create(:channel => event.channel, :timestamp => Time.now,
                      :nick => event.nick, :line => event.message)
    when :action
      Message.create(:channel => event.channel, :timestamp => Time.now,
                      :nick => "* #{event.nick}", :line => event.message)
  end
end

def go!
  irc = Net::YAIL.new(
    :address   => Config['server'],
    :username  => Config['username'],
    :realname  => Config['realname'],
    :nicknames => Config['nicknames']
  )

  irc.on_welcome do
    Config['channels'].each do |channel|
      irc.join channel
    end
  end

  irc.on_topic_change do |e|
    log :system, e, "#{e.from} changed the topic of #{e.channel} to: #{e.message}"
  end

  irc.on_join do |e|
    log :system, e, "#{e.nick} [#{e.fullname}] has joined #{e.channel}"
  end

  irc.on_part do |e|
    log :system, e, "#{e.nick} [#{e.fullname}] has quit [#{e.message}]"
  end

  irc.on_kick do |e|
    log :system, e, "#{e.target} was kicked from #{e.channel} by #{e.nick} [#{e.message}]"
  end

  irc.on_msg do |e|
    log :message, e
  end

  irc.on_act do |e|
    log :action, e
  end

  irc.start_listening

  trap("INT")  { exit }
  trap("QUIT") { exit }

  sleep 1 until irc.dead_socket
end

loop do
  begin
    go!
  rescue StandardError => e
    puts "#{e.class}: #{e.message}"
    e.backtrace.each { |line| puts "  #{line}" }
  end

  sleep 1
end
