require 'zlib' # crc32

module IrcLogger
  module ViewerHelpers
    include Rack::Utils
    
    CHANNEL_ESCAPE = {
      '~' => '~~',
      '#' => '~h~',
      '/' => '~s~',
      '%' => '~p~',
      '\\' => '~r~',
      '?' => '~q~',
      '`' => '~a~',
      '<' => '~l~',
      '>' => '~g~',
      '|' => '~b~',
      '{' => '~o~',
      '}' => '~c~',
      '^' => '~x~',
      '"' => '~d~'
    }
    CHANNEL_ESCAPE_INVERTED = CHANNEL_ESCAPE.invert
    
    def escape_url(url)
      url.gsub(/(.)/) { |m| CHANNEL_ESCAPE.key?(m) ? CHANNEL_ESCAPE[m] : m }
    end
    
    def unescape_url(url)
      url.gsub(/~[^~]?~/) { |m| CHANNEL_ESCAPE_INVERTED.key?(m) ? CHANNEL_ESCAPE_INVERTED[m] : m }
    end
        

    def channel_escape(channel)
      escape_url(channel[1..-1])
    end

    def channel_unescape(channel)
      c = unescape_url(channel)
      if Config.key?('legacy') && Config['legacy'].include?(c) then
        "##{c.gsub(/^\.+/) { |m| '#' * m.length }}"
      end
      "##{c}"
    end

    def channel_url(channel, postfix=nil)
      "/#{channel_escape channel}/#{postfix}"
    end

    def nick_class(nick)
      color = Zlib.crc32(nick) % 16 + 1
      "nick nick-#{color}"
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
          if text =~ %r{\Ahttps?://}
            link = text
          else
            link = "http://#{text}"
          end
          %(#{a}<a href="#{link}" class="link" target="_blank">#{text}</a>#{d})
        end
      end.
        # *bold*
        gsub(/(^|\s)(\*[^\s](?:|.*?[^\s])\*)(\s|$)/, '\1<b>\2</b>\3').
        # _underlined_
        gsub(/(^|\s)(_[^\s](?:|.*?[^\s])_)(\s|$)/, '\1<u>\2</u>\3').
        # strip color codes
        gsub(/[\x02\x09\x13\x0f\x15\x16\x1f]|\x03\d{1,2}(,\d{1,2})?/, '').
        gsub(Message::NICK_PATTERN) do
          if nicks && nicks.include?($1)
            "<span class='chain #{nick_class($1)}'>#$1</span>"
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
            %Q{<a class="#{current}" href="#{channel_url channel, d}">#{$1}</a>}
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
            %Q{<a href="#{channel_url channel, date}">#{text}</a>}
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
end
