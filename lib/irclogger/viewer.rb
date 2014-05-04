require 'date'

require 'sinatra/base'
require 'sinatra/reloader'
require 'haml'
require 'sass'

require 'irclogger/channel'
require 'irclogger/viewer_helpers'

module IrcLogger
  class Viewer < Sinatra::Base
    set :views,         File.expand_path('../../../views', __FILE__)
    set :public_folder, File.expand_path('../../../public', __FILE__)

    configure :development do
      register Sinatra::Reloader
    end

    helpers ViewerHelpers

    before do
      @channels = DB["select channel from irclog group by channel"].map { |r| r[:channel] }
      if (hidden_channels = Config['hidden_channels'])
        @channels -= hidden_channels
      end
    end

    get '/' do
      haml :index
    end

    get '/help/search' do
      haml :'help/search'
    end

    get '/style-dark.css' do
      sass :'style-dark'
    end

    get '/style-light.css' do
      sass :'style-light'
    end

    get '/:channel' do
      redirect "/#{params[:channel]}/"
    end

    get '/:channel/search' do
      @channel = channel_unescape(params[:channel])
      @limit   = 300

      if params[:q] && params[:q].length >= 3
        @messages      = Message.search_in_channel(@channel, params[:q])
        @message_count = @messages.count

        @messages      = @messages.limit(@limit, ((params[:page] || 1).to_i - 1) * @limit)
      else
        @message_count = 0
      end

      haml :search
    end

    get '/:channel/stream', provides: 'text/event-stream' do
      response['X-Accel-Buffering'] = 'no'

      channel = channel_unescape(params[:channel])

      last_message_id = env['HTTP_LAST_EVENT_ID'] || params['last_id']
      last_messages   = Message.recent_for_channel(channel, last_message_id.to_i)

      render_one = lambda do |stream, message|
        stream << "id: #{message.id}\n"

        html = haml(:_message, locals: { message: message, dates: false }, layout: false)
        html.lines.each do |line|
          stream << "data: #{line}" # \n is already there
        end

        stream << "\n"
      end

      stream :keep_open do |out|
        last_messages.each do |message|
          render_one.(out, message)
        end

        subscriber_id = Channel.subscribe(channel) do |message|
          render_one.(out, message)
        end

        proc = -> { Channel.unsubscribe(channel, subscriber_id) }
        out.callback(&proc)
        out.errback(&proc)
      end
    end

    get '/:channel/index/' do |channel|
      @channel = channel_unescape(channel)
      @index   = Message.date_index_for_channel(@channel)

      haml :channel_index
    end

    get '/:channel/index/:elem' do |channel, elem|
      redirect to("/#{channel}/#{elem}"), 301
    end

    get '/:channel/:interval?.?:format?' do |channel, interval, format|
      @channel = channel_unescape(channel)

      begin
        if interval =~ /^\d+-\d+-\d+$/
          @date     = Date.parse(interval)
          @messages = Message.find_by_channel_and_date(@channel, @date)
        elsif interval =~ /^\d+-\d+$/ && %w(txt).include?(format)
          @date     = Date.parse(interval + "-01")
          @messages = Message.find_by_channel_and_month(@channel, @date)
        else
          raise ArgumentError, "invalid interval"
        end

      rescue ArgumentError # invalid date or interval
        redirect channel_url(@channel, Time.now.gmtime.to_date)
      end

      case format
      when 'txt'
        response['Content-Type'] = 'text/plain'

        @messages.map(&:to_s).join("\n")
      else
        @is_today = (@date == Time.now.gmtime.to_date)
        @topic    = Message.most_recent_topic_for(@channel, @date)

        haml :channel
      end
    end
  end
end
