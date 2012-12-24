require "rubygems"
require "bundler/setup"
$: << File.join(File.dirname(__FILE__), 'lib')

require 'sinatra'
require 'haml'
require 'sass'
require 'date'
require 'irclogger'
require 'em-hiredis'

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
end

EM::next_tick do
  pubsub = EM::Hiredis.connect(Config['redis'])
  pubsub.subscribe('message')
  pubsub.on(:message) do |redis_channel, message|
    channel, message_id = message.split
    Channel.notify(channel, message_id)
  end
end

helpers do
  include Rack::Utils

  def channel(name)
    name[1..-1].gsub '#', '.'
  end

  AUTO_LINK_REGEXP = %r{
      (                          # leading text
        <\w+.*?>|                # leading HTML tag, or
        [^=!:'"/]|               # leading punctuation, or
        ^                        # beginning of line
      )
      (
        https?://|               # protocol spec, or
        www\.                    # www.*
      )
      (
        [-\w]+                   # subdomain or domain
        (?:\.[-\w]+)*            # remaining subdomains or domain
        (?::\d+)?                # port
        (?:/(?:(?:[~\w\+@%=\(\)-]|(?:[,.;:'][^\s$])))*)* # path
        (?:\?[\w\+@%&=.;-]+)?    # query string
        (?:\#[\w\-!:/]*)?        # trailing anchor
      )
      ([[:punct:]]|<|$|)         # trailing text
    }xi

  def format_message(text, nicks=nil)
    text.gsub('&#x2F;', '/').gsub(AUTO_LINK_REGEXP) do
      all, a, b, c, d = $&, $1, $2, $3, $4
      if a =~ /<a\s/i # don't replace URL's that are already linked
        all
      else
        text = b + c
        %(#{a}<a href="#{text}" class="link" target="_blank">#{text}</a>#{d})
      end
    end.
      # *bold*
      gsub(/(^|\s)(\*[^\s](?:|.*?[^\s])\*)(\s|$)/, '\1<b>\2</b>\3').
      # _underlined_
      gsub(/(^|\s)(_[^\s](?:|.*?[^\s])_)(\s|$)/, '\1<u>\2</u>\3').
      gsub(Message::NICK_PATTERN) do
        if nicks && nicks.include?($1)
          "<span class='chain'>#$1</span>"
        else
          $&
        end
      end
  end

  CAL_CACHE = Hash.new do |h, k|
                h[k] = `cal #{k}`.split("\n")
              end

  def calendar(channel, date=nil, links=true)
    origin = date || Date.today

    cal = CAL_CACHE["#{origin.month} #{origin.year}"]
    cal = "\n<span class='header'>#{cal[1]}</span>\n" + cal[2..-1].join("\n")
    cal.gsub!("_\b", '')

    if links
      cal.gsub!(/\b(\d{1,2})\b/) do
        d = origin.strftime("%Y-%m-#{$1.rjust 2, "0"}")
        current = "current" if date && date.to_s == d

        if Message.check_by_channel_and_date(channel, Date.parse(d))
          %Q{<a class="#{current}" href="/#{channel channel}/#{d}">#{$1}</a>}
        else
          $1
        end
      end
    end

    next_date = origin >> 1
    prev_date = origin << 1

    header = "<span class='header'>#{origin.strftime("%B %Y").center(18)}</span>"
    if links
      link_if = ->(date, text) do
        if Message.check_by_channel_and_month(channel, date)
          %Q{<a href="/#{channel channel}/#{date}">#{text}</a>}
        else
          text
        end
      end

      link_if.(prev_date, '&lt;') + header + link_if.(next_date, '&gt;') + cal
    else
      %Q{&lt;#{header}&gt;#{cal}}
    end
  end
end

before do
  @channels = DB["select channel from irclog group by channel"].map { |r| r[:channel] }
end

get '/' do
  haml :index
end

get '/help/search' do
  haml :search_help
end

get '/style.css' do
  sass :style
end

get '/:channel' do
  redirect "/#{params[:channel]}/"
end

get '/:channel/search' do
  @channel = "##{params[:channel].gsub '.', '#'}"
  @limit   = 300

  if params[:q].length >= 3
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

  channel = "##{params[:channel].gsub '.', '#'}"

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

get '/:channel/:date?' do
  @channel = "##{params[:channel].gsub '.', '#'}"

  if params[:date]
    @date     = Date.parse(params[:date])
    @is_today = (@date == Time.now.gmtime.to_date)

    dataset   = Message.find_by_channel_and_date(@channel, @date)
    @nicks    = Message.nicks(dataset)
    @messages = Message.track_chains(dataset, @nicks)
    @topic    = Message.most_recent_topic_for(@channel, @date)

    haml :channel
  else
    redirect "/#{params[:channel]}/#{Time.now.gmtime.to_date}"
  end
end