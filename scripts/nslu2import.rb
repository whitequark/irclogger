#!/usr/bin/env ruby

$: << File.join(File.dirname(__FILE__), '../lib')

require 'irclogger'

ARGV.each do |filename|
  DB.transaction do
    print File.basename(filename)
    if File.basename(filename) =~ /^(.+?).(\d{8})\.txt$/
      print "$2"
      date = Date.parse "#{$2}"
    else
      raise "malformed date"
    end
    puts date

    File.foreach(filename) do |line|
      unless line.valid_encoding?
        line = line.force_encoding(Encoding::WINDOWS_1252).encode(Encoding::UTF_8)
      end

      if line =~ /^\*\*\*\* (BEGIN|ENDING)/
        next # ignore
      elsif line =~ /^.{3} \d{2} (\d{2}):(\d{2}):(\d{2}) (.*)/
        time = date.to_time + $1.to_i * 3600 + $2.to_i * 60 + $3.to_i
        rest = $4
      elsif line == ""
        next
      elsif line == "\n"
        next
      else
        p line
        raise "malformed timestamp"
      end

      opts = { channel: '#openwrt-devel', timestamp: time }

      case rest
      when /^<(.+?)> (.*)$/
        Message.create(opts.merge nick: $1, line: $2)
      when /^(\* \S+) (.*)$/
        Message.create(opts.merge nick: $1, line: $2)
      when /^(\* \S+)$/
        Message.create(opts.merge nick: $1, line: "")
      else
        raise "unknown rest: #{rest}"
      end
    end
  end
end
