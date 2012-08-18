#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
$: << File.join(File.dirname(__FILE__), 'lib')

require 'set'
require 'irclogger'
require 'cinch'

pidfile = File.join(File.dirname(__FILE__), 'tmp', 'logger.pid')
File.open(pidfile, 'w') do |f|
  f.write Process.pid
end

bot = Cinch::Bot.new do
  configure do |c|
    c.server   = Config['server']
    c.channels = Config['channels']
    c.user     = Config['username']
    c.nick     = Config['nickname']
    c.realname = Config['realname']
  end

  options = lambda do |m, options|
    {
      channel:   m.channel,
      timestamp: m.time
    }.merge(options)
  end

  user_lists = Hash.new { |h,k| h[k] = Set.new }
  user_lists_mutex = Mutex.new

  on :channel do |m|
    unless m.action?
      Message.create(options.(m, nick: m.user.nick, line: m.message))
    end
  end

  on :action do |m|
    Message.create(options.(m, nick: "* " + m.user.nick, line: m.action_message))
  end

  on :topic do |m|
    Message.create(options.(m, line:
        "#{m.user.nick} changed the topic of #{m.channel} to: #{m.message}"))
  end

  on :join do |m|
    Message.create(options.(m, line:
        "#{m.user.nick} has joined #{m.channel}"))

    user_lists_mutex.synchronize do
      if m.user.nick == bot.nick
        user_lists[m.channel.name] = m.channel.users.keys.map(&:nick).to_set
      end

      user_lists[m.channel.name].add m.user.nick
    end
  end

  on :part do |m|
    Message.create(options.(m, line:
        "#{m.user.nick} has left #{m.channel} [#{m.message}]"))

    user_lists_mutex.synchronize do
      user_lists[m.channel.name].delete m.user.nick
    end
  end

  on :kick do |m|
    Message.create(options.(m, line:
        "#{m.params[1]} was kicked from #{m.channel} by #{m.user.nick} [#{m.message}]"))

    user_lists_mutex.synchronize do
      user_lists[m.channel.name].delete m.user.nick
    end
  end

  on :nick do |m|
    user_lists_mutex.synchronize do
      user_lists.each do |channel, users|
        if users.include? m.user.last_nick
          Message.create(options.(m,
              channel: channel,
              line:    "#{m.user.last_nick} is now known as #{m.user.nick}"))

          users.delete m.user.last_nick
          users.add m.user.nick
        end
      end
    end
  end

  on :quit do |m|
    user_lists_mutex.synchronize do
      user_lists.each do |channel, users|
        if users.include? m.user.nick
          Message.create({
            timestamp: m.time,
            channel:   channel,
            line:      "#{m.user.nick} has quit [#{m.message}]"
          })

          users.delete m.user.nick
        end
      end
    end
  end
end

bot.start
