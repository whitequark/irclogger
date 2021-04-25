#!/usr/bin/env ruby

$: << File.join(File.dirname(__FILE__), '../lib')

require 'irclogger'

mask = "\\(.*?\\)"

ARGV.each do |filename|
  if File.basename(filename) =~ /(#.+?)\.weechatlog$/
    puts "importing channel #{$1}..."
    channel = $1
  else
    raise "malformed weechatlog filename #{filename}"
  end

  DB.transaction do
    File.foreach(filename) do |line|
      unless line.valid_encoding?
        line = line.force_encoding(Encoding::WINDOWS_1252).encode(Encoding::UTF_8)
      end

      if line =~ /^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\t(.*)$/
        time = (DateTime.parse $1).to_time
        rest = $2
      elsif line == ""
        next
      else
        p line
        raise "malformed timestamp"
      end

      opts = { channel: channel, timestamp: time }

      case rest
      when /^--\t\[(.*?)\]/
        # ignore notices
      when /^--\t(?:irc|Notice|Mode|Topic (set|for)|Channel|You are|Nicks)/
        # ignore various statuses
      when /^--\t#{opts[:channel]}: (?:Unknown|Cannot)/
        # ignore more statuses
      when /^-->\t(\S+) #{mask} has joined #{opts[:channel]}$/
        Message.create(opts.merge nick: $1, opcode: 'join', line: "#{$1} has joined #{opts[:channel]}")
      when /^<--\t(\S+) #{mask} has left #{opts[:channel]}(?: \("(.*)"\))?$/
        Message.create(opts.merge nick: $1, opcode: 'leave', line: "#{$1} has left #{opts[:channel]} [#{$2}]",
                       payload: "")
      when /^<--\t(\S+) #{mask} has quit(?: \((.*)\))?$/
        Message.create(opts.merge nick: $1, opcode: 'quit', line: "#{$1} has quit [#{$2}]",
                       payload: $2)
      when /^--\t(\S+) is now known as (\S+)$/
        Message.create(opts.merge nick: $1, opcode: 'nick', line: "#{$1} is now known as #{$2}",
                       payload: $2)
      when /^--\t(\S+) has changed topic for #{opts[:channel]} from "(.*?)" to "(.*?)"$/
        Message.create(opts.merge nick: $1, opcode: 'topic',
                       line: "#{$1} changed the topic of #{opts[:channel]} to: #{$3}",
                       payload: $3)
      when /^<--\t(\S+) has kicked (\S+)(?: \(.*?\))?$/
        Message.create(opts.merge nick: $1, opcode: 'kick',
                       line: "#{$2} was kicked from #{opts[:channel]} by #{$1} [#{$3}]",
                       oper_nick: $1,
                       payload: $3)
      when /^([^\s<-]\S*)\t(.*)$/
        Message.create(opts.merge nick: $1, line: $2)
      when /^ \*\t(\S+) (.*)$/
        Message.create(opts.merge nick: "* #{$1}", line: $2)
      when /^ \*\t(\S+)$/
        Message.create(opts.merge nick: "* #{$1}", line: "")
      else
        raise "unknown rest: #{rest}"
      end
    end
  end
end
