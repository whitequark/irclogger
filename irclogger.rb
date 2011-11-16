require "rubygems"
require "bundler/setup"

require 'date'
require 'sequel'
require 'sinatra'

DB = Sequel.connect 'mysql2://irc:Z3VxBPe3XQSj4QTmw3@localhost/irclogs'

class Message < Sequel::Model(:irclog)
  def type
    if talk?
      "talk"
    elsif info?
      "info"
    end
  end

  def talk?
    !nick.empty?
  end

  def info?
    nick.empty?
  end

  def self.find_by_channel_and_date(channel, date)
    day_after = date + 1

    filter('timestamp > ? and timestamp < ?',
                  Time.local(date.year, date.month, date.day).to_i,
                  Time.local(day_after.year, day_after.month, day_after.day).to_i).
      filter(:channel => channel).
      order(:timestamp)
  end

  def self.find_by_channel_and_fulltext(channel, query)
    filter(:channel => channel).
      filter('(nick like ? or line like ?)', "%#{query}%", "%#{query}%").
      order(:timestamp)
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
        (?:\?[\w\+@%&=.;-]+)?     # query string
        (?:\#[\w\-]*)?           # trailing anchor
      )
      ([[:punct:]]|<|$|)       # trailing text
    }xi

  # Turns all urls into clickable links.  If a block is given, each url
  # is yielded and the result is used as the link text.
  def auto_link_urls(text)
    text.gsub('&#x2F;', '/').gsub(AUTO_LINK_REGEXP) do
      all, a, b, c, d = $&, $1, $2, $3, $4
      if a =~ /<a\s/i # don't replace URL's that are already linked
        all
      else
        text = b + c
        text = yield(text) if block_given?
        %(#{a}<a href="#{text}" class="link" target="_blank">#{text}</a>#{d})
      end
    end
  end

  def calendar(channel, date=nil, links=true)
    origin = date || Date.today
    cal = `cal #{origin.month} #{origin.year}`.split("\n")[1..-1].join("\n")

    if links
      cal.gsub!(/\b(\d{1,2})\b/) do
        d = origin.strftime("%Y-%m-#{$1.rjust 2, "0"}")
        current = "current" if date && date.to_s == d

        if Message.find_by_channel_and_date(channel, Date.parse(d)).any?
          %Q{<a class="#{current}" href="/#{channel channel}/#{d}">#{$1}</a>}
        else
          $1
        end
      end
    end

    next_date = origin >> 1
    prev_date = origin << 1

    if links
      %Q{<a href="/#{channel channel}/#{prev_date}">&lt;</a>} +
        origin.strftime("%B %Y").center(18) +
        %Q{<a href="/#{channel channel}/#{next_date}">&gt;</a>\n} +
        cal
    else
      %Q{&lt;#{origin.strftime("%B %Y").center(18)}&gt;\n#{cal}}
    end
  end
end

before do
  @channels = DB["select channel from irclog group by channel"].map { |r| r[:channel] }
end

get '/' do
  haml :index
end

get '/style.css' do
  sass :style
end

get '/:channel' do
  redirect "/#{params[:channel]}/"
end

get '/:channel/search' do
  @channel = "##{params[:channel].gsub '.', '#'}"
  @limit = 300

  if params[:q].length >= 3
    @messages = Message.find_by_channel_and_fulltext(@channel, params[:q])
    if @messages.count > @limit
      @messages = @messages.limit(@limit)
      @over_limit = true
    end
  end

  haml :search
end

get '/:channel/:date?' do
  @channel = "##{params[:channel].gsub '.', '#'}"
  if params[:date]
    @date = Date.parse(params[:date])
    @messages = Message.find_by_channel_and_date(@channel, @date)

    haml :channel
  else
    redirect "/#{params[:channel]}/#{Date.today}"
  end
end
