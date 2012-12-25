require 'em-hiredis'

module IrcLogger
  module Channel
    @subscribers = Hash.new { |h, k| h[k] = [] }

    def self.subscribe(channel, &block)
      @subscribers[channel] << block

      block
    end

    def self.unsubscribe(channel, block)
      @subscribers[channel].delete block

      nil
    end

    def self.notify(channel, message_id)
      message = Message[message_id]

      @subscribers[channel].each do |block|
        block.call(message)
      end
    end

    def self.listen
      EM::next_tick do
        pubsub = EM::Hiredis.connect(Config['redis'])

        pubsub.subscribe('message')

        pubsub.on(:message) do |redis_channel, message|
          channel, message_id = message.split
          notify(channel, message_id)
        end
      end
    end
  end
end