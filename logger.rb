#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
$: << File.join(File.dirname(__FILE__), 'lib')

require 'set'
require 'irclogger'
require 'cinch'
require 'redis'

pidfile = File.join(File.dirname(__FILE__), 'tmp', 'logger.pid')
File.open(pidfile, 'w') do |f|
  f.write Process.pid
end

redis = Redis.new(url: Config['redis'])

bot = Cinch::Bot.new do
  configure do |c|
    c.server   = Config['server']
    c.channels = Config['channels']
    c.user     = Config['username']
    c.nick     = Config['nickname']
    c.realname = Config['realname']
  end

  post_message = lambda do |*args|
    message = Message.create(*args)
    redis.publish('message', "#{message.channel} #{message.id}")
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
      post_message.(options.(m,
          nick: m.user.nick,
          line: m.message))
    end
  end

  on :action do |m|
    post_message.(options.(m,
        nick: "* " + m.user.nick,
        line: m.action_message))
  end

  on :topic do |m|
    post_message.(options.(m,
        opcode: 'topic',
        nick:   m.user.nick,
        line:   "#{m.user.nick} changed the topic of #{m.channel} to: #{m.message}"))
  end

  on :join do |m|
    post_message.(options.(m,
        opcode: 'join',
        nick:   m.user.nick,
        line:   "#{m.user.nick} has joined #{m.channel}"))

    user_lists_mutex.synchronize do
      if m.user.nick == bot.nick
        user_lists[m.channel.name] = m.channel.users.keys.map(&:nick).to_set
      end

      user_lists[m.channel.name].add m.user.nick
    end
  end

  on :part do |m|
    post_message.(options.(m,
        opcode: 'leave',
        nick:   m.user.nick,
        line:   "#{m.user.nick} has left #{m.channel} [#{m.message}]"))

    user_lists_mutex.synchronize do
      user_lists[m.channel.name].delete m.user.nick
    end
  end

  on :kick do |m|
    post_message.(options.(m,
        opcode: 'kick',
        nick:   m.params[1],
        line:   "#{m.params[1]} was kicked from #{m.channel} by #{m.user.nick} [#{m.message}]"))

    user_lists_mutex.synchronize do
      user_lists[m.channel.name].delete m.user.nick
    end
  end

  on :ban do |m, ban|
    user = m.channel.users.find {|user, _| ban.match(user)}.first
    actual_nick = user && user.nick

    if actual_nick
      post_message.(options.(m,
          opcode: 'ban',
          nick:   actual_nick,
          line:   "#{actual_nick} was banned on #{m.channel} by #{m.user.nick} [#{m.message}]"))
    end
  end

  on :nick do |m|
    user_lists_mutex.synchronize do
      user_lists.each do |channel, users|
        if users.include? m.user.last_nick
          post_message.(options.(m,
              channel: channel,
              opcode:  'nick',
              nick:    m.user.last_nick,
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
          post_message.({
            timestamp: m.time,
            channel:   channel,
            opcode:    'quit',
            nick:      m.user.nick,
            line:      "#{m.user.nick} has quit [#{m.message}]"
          })

          users.delete m.user.nick
        end
      end
    end
  end
end

bot.start
