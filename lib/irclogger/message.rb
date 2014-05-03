require 'set'

class Message < Sequel::Model(:irclog)
  NICK_PATTERN = /^([A-Za-z_0-9|.`-]+)/ # `

  def type
    if talk?
      "talk"
    elsif me_tell?
      "me-tell"
    elsif info?
      "info"
    end
  end

  def me_tell?
    nick && nick[0] == '*'
  end

  def talk?
    opcode.nil? && !me_tell?
  end

  def info?
    !opcode.nil?
  end

  def to_s
    Time.at(timestamp).gmtime.strftime("%Y-%m-%d %H:%M") +
      if talk?
        " <#{nick}> #{line}"
      elsif me_tell?
        " #{nick} #{line}"
      else
        " #{line}"
      end
  end

  def self.nicks(messages)
    messages.
        filter('nick is not null').
        select(:nick).distinct(:nick).
        map(&:nick).to_set
  end

  def self.find_by_channel_and_date(channel, date)
    day_after = date + 1

    filter('timestamp > ? and timestamp < ?',
                  Time.utc(date.year, date.month, date.day).to_i,
                  Time.utc(day_after.year, day_after.month, day_after.day).to_i).
      filter(:channel => channel).
      order(:timestamp)
  end

  def self.check_by_channel_and_date(channel, date)
    find_by_channel_and_date(channel, date).
        filter('opcode is null').
        count > 0
  end

  def self.find_by_channel_and_month(channel, date)
    from = Time.utc(date.year, date.month, 1)
    to   = Time.utc((date >> 1).year, (date >> 1).month, 1) - 1

    filter('timestamp > ? and timestamp < ?', from.to_i, to.to_i).
        filter(:channel => channel).
        order(:timestamp)
  end

  def self.check_by_channel_and_month(channel, date)
    from = Time.utc(date.year, date.month, 1)
    to   = Time.utc((date >> 1).year, (date >> 1).month, 1) - 1

    filter('timestamp > ? and timestamp < ?', from.to_i, to.to_i).
        filter(:channel => channel).
        count > 0
  end

  def self.search_in_channel(channel, query)
    if query =~ /^kickban:(.*)/
      find_by_channel_and_kickban(channel, $1)
    elsif query =~ /^nick:(.*)/
      find_by_channel_and_nick(channel, $1)
    else
      find_by_channel_and_fulltext(channel, query)
    end
  end

  def self.find_by_channel_and_kickban(channel, query)
    order(:timestamp).reverse.filter(:channel => channel).
        filter('opcode = "kick" or opcode = "ban"').
        filter('nick like ?', query.strip + "%")
  end

  def self.find_by_channel_and_fulltext(channel, query)
    order(:timestamp).reverse.filter(:channel => channel).
        filter('opcode is null').
        filter('match (nick, line) against (? in boolean mode)', query)
  end

  def self.find_by_channel_and_nick(channel, query)
    order(:timestamp).reverse.filter(:channel => channel).
        filter('opcode is null').
        filter('nick like ?', query.strip + "%")
  end

  def self.any_recent_messages?(interval = 600)
    filter('timestamp > ?', Time.now.to_i - interval).any?
  end

  def self.most_recent_topic_for(channel, date)
    order(:timestamp).
        filter(channel: channel, opcode: 'topic').
        filter('timestamp < ?', date.to_time.to_i).
        last
  end

  def self.recent_for_channel(channel, id)
    order(:timestamp).
        filter(channel: channel).
        filter('timestamp > ?', Time.now.to_i - 86400). # failsafe
        filter('id > ?', id)
  end

  def self.date_index_for_channel(channel)
    filter(channel: channel).
        select{date(from_unixtime(timestamp)).as(:date)}.
        distinct.
        map(:date)
  end
end
