require 'cinch'

module IrcLogger
  class CinchPlugin
    include Cinch::Plugin

    class << self
      attr_accessor :redis
    end

    def initialize(*)
      super

      @user_lists = Hash.new { |h,k| h[k] = Set.new }
    end

    def redis
      self.class.redis
    end
    protected :redis

    def post_message(*args)
      message = Message.create(*args)
      redis.publish("message.#{Config['server']}", "#{message.channel} #{message.id}")
    end

    def options(message, other_options={})
      {
        channel:   message.channel,
        timestamp: message.time
      }.merge(other_options)
    end

    listen_to :channel, method: :on_channel
    def on_channel(m)
      unless m.action?
        post_message(options(m,
            nick: m.user.nick,
            line: m.message))
      end
    end

    listen_to :action, method: :on_action
    def on_action(m)
      post_message(options(m,
          nick: "* " + m.user.nick,
          line: m.action_message))
    end

    listen_to :topic, method: :on_topic
    def on_topic(m)
      post_message(options(m,
          opcode:  'topic',
          nick:    m.user.nick,
          line:    "#{m.user.nick} changed the topic of #{m.channel} to: #{m.message}",
          payload: m.message))
    end

    listen_to :join, method: :on_join
    def on_join(m)
      post_message(options(m,
          opcode: 'join',
          nick:   m.user.nick,
          line:   "#{m.user.nick} has joined #{m.channel}"))

      synchronize(:user_lists) do
        if m.user.nick == bot.nick
          @user_lists[m.channel.name] = m.channel.users.keys.map(&:nick).to_set
        end

        @user_lists[m.channel.name].add m.user.nick
      end
    end

    listen_to :part, method: :on_part
    def on_part(m)
      post_message(options(m,
          opcode:  'leave',
          nick:    m.user.nick,
          line:    "#{m.user.nick} has left #{m.channel} [#{m.message}]",
          payload: m.message))

      synchronize(:user_lists) do
        @user_lists[m.channel.name].delete m.user.nick
      end
    end

    listen_to :kick, method: :on_kick
    def on_kick(m)
      post_message(options(m,
          opcode:    'kick',
          nick:      m.params[1],
          line:      "#{m.params[1]} was kicked from #{m.channel} by #{m.user.nick} [#{m.message}]",
          oper_nick: m.user.nick,
          payload:   m.message))

      synchronize(:user_lists) do
        @user_lists[m.channel.name].delete m.user.nick
      end
    end

    listen_to :ban, method: :on_ban
    def on_ban(m, ban)
      user = m.channel.users.find {|user, _| ban.match(user)}.first
      actual_nick = user && user.nick

      if actual_nick
        post_message(options(m,
            opcode:    'ban',
            nick:      actual_nick,
            line:      "#{actual_nick} was banned on #{m.channel} by #{m.user.nick} [#{m.message}]",
            oper_nick: m.user.nick,
            payload:   m.message))
      end
    end

    listen_to :nick, method: :on_nick
    def on_nick(m)
      synchronize(:user_lists) do
        @user_lists.each do |channel, users|
          if users.include? m.user.last_nick
            post_message(options(m,
                channel: channel,
                opcode:  'nick',
                nick:    m.user.last_nick,
                line:    "#{m.user.last_nick} is now known as #{m.user.nick}",
                payload: m.user.nick))

            users.delete m.user.last_nick
            users.add m.user.nick
          end
        end
      end
    end

    listen_to :quit, method: :on_quit
    def on_quit(m)
      synchronize(:user_lists) do
        @user_lists.each do |channel, users|
          if users.include? m.user.nick
            post_message({
              timestamp: m.time,
              channel:   channel,
              opcode:    'quit',
              nick:      m.user.nick,
              line:      "#{m.user.nick} has quit [#{m.message}]",
              payload:   m.message
            })

            users.delete m.user.nick
          end
        end
      end
    end
  end
end
