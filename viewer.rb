require "rubygems"
require "bundler/setup"
$: << File.join(File.dirname(__FILE__), 'lib')

require 'sinatra'
require 'date'
require 'irclogger'

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
      gsub(/(^|\s)(\*[^\s](?:|.*?[^\s])\*)(\s|$)/, '\1<b>\2</b>\3').
      gsub(/(^|\s)(_[^\s](?:|.*?[^\s])_)(\s|$)/, '\1<u>\2</u>\3').
      gsub(/^([A-Za-z_0-9|.`-]+)/) do
        if nicks && nicks.include?($1)
          "<span class='chain'>#$1</span>"
        else
          $&
        end
      end
  end

  def calendar(channel, date=nil, links=true)
    origin = date || Date.today
    cal = `cal #{origin.month} #{origin.year}`.split("\n")
    cal = "<span class='header'>#{cal[1]}</span>\n" + cal[2..-1].join("\n")

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
      %Q{<a href="/#{channel channel}/#{prev_date}">&lt;</a>} +
         header +
        %Q{<a href="/#{channel channel}/#{next_date}">&gt;</a>\n} +
        cal
    else
      %Q{&lt;#{header}&gt;\n#{cal}}
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

    dataset = Message.find_by_channel_and_date(@channel, @date)
    @messages = Message.track_chains(dataset)
    @nicks = Message.nicks(dataset)

    haml :channel
  else
    redirect "/#{params[:channel]}/#{Time.now.gmtime.to_date}"
  end
end
