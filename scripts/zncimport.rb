#!/usr/bin/env ruby

$: << File.join(File.dirname(__FILE__), '../lib')

require 'irclogger'

# This imports ZNC logs
# might be identical to the mIRC log format too

ARGV.each do |filename|
  DB.transaction do
    if File.basename(filename) =~ /^(\d{4}.\d{2}.\d{2}).log$/
      puts "Importing #{$1}..."
      date = Date.parse "#{$1}"
    else
      raise "malformed date"
    end

    File.foreach(filename) do |line|
      unless line.valid_encoding?
        line = line.force_encoding(Encoding::WINDOWS_1252).encode(Encoding::UTF_8)
      end

      if line =~ /^\[(\d{2}):(\d{2}):(\d{2})\] (.*)/
        time = date.to_time + $1.to_i * 3600 + $2.to_i * 60 + $3.to_i
        rest = $4
      elsif line == ""
        next
      else
        p line
        raise "malformed timestamp"
      end

      opts = { channel: '#rebuild', timestamp: time }

      case rest
      when /^\*\*\* (\S+) sets (log|names|mode):/
        # ignore
      when /^-[A-Za-z0-9_|.`-]+\(.+?\)- /
        # ignore
      when /^<> (.*)/
        # this is possible (???), ignore it
      when /^<(.+?)> (.*)$/
        Message.create(opts.merge nick: $1, line: $2)
      when /^(\* \S+) (.*)$/
        Message.create(opts.merge nick: $1, line: $2)
      when /^(\* \S+)$/
        Message.create(opts.merge nick: $1, line: "")
      when /^\*\*\* Joins: (\S+) \(.*?\)$/
        Message.create(opts.merge nick: $1, opcode: 'join', line: "#{$1} has joined #{opts[:channel]}")
      when /^\*\*\* Parts: (\S+) (\S+) \(.*?\)$/
        Message.create(opts.merge nick: $1, opcode: 'leave', line: "#{$1} has left #{opts[:channel]} [#{$3}]",
                       payload: "")
      when /^\*\*\* Quits: (\S+) \((.*)\)$/
        Message.create(opts.merge nick: $1, opcode: 'quit', line: "#{$1} has quit [#{$2}]",
                       payload: $2)
      when /^\*\*\* (\S+) is now known as (\S+)$/
        if "#{$2}".length < 40 and "#{$1}".length < 40
          Message.create(opts.merge nick: $1, opcode: 'nick', line: "#{$1} is now known as #{$2}",
            payload: $2)
        end
      when /^\*\*\* (\S+) changes topic to '(.*?)'$/
        Message.create(opts.merge nick: $1, opcode: 'topic',
                       line: "#{$1} changed the topic of #{opts[:channel]} to: #{$2}",
                       payload: $2)
      when /^\*\*\* (\S+) was kicked by (\S+) (.*?)$/
        Message.create(opts.merge nick: $2, opcode: 'kick',
                       line: "#{$1} was kicked from #{opts[:channel]} by #{$2} [#{$3}]",
                       oper_nick: $2,
                       payload: $3)
      else
        raise "unknown rest: #{rest}"
      end
    end
  end
end