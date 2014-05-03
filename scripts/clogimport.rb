#!/usr/bin/env ruby

$: << File.join(File.dirname(__FILE__), '../lib')

require 'irclogger'

ARGV.each do |filename|
  DB.transaction do
    if File.basename(filename) =~ /^(\d{2}.\d{2}.\d{2})$/
      date = Date.parse "20#{$1}"
    else
      raise "malformed date"
    end
    puts date

    File.foreach(filename) do |line|
      unless line.valid_encoding?
        line = line.force_encoding(Encoding::WINDOWS_1252).encode(Encoding::UTF_8)
      end

      if line =~ /^(\d{2}):(\d{2}):(\d{2}) (.*)/
        time = date.to_time + $1.to_i * 3600 + $2.to_i * 60 + $3.to_i
        rest = $4
      elsif line == ""
        next
      else
        p line
        raise "malformed timestamp"
      end

      opts = { channel: '#ocaml', timestamp: time }

      case rest
      when /^--- (log|names|mode):/
        # ignore
      when /^-[A-Za-z0-9_|.`-]+\(.+?\)- /
        # ignore notices
      when /^<(.+?)> (.*)$/
        Message.create(opts.merge nick: $1, line: $2)
      when /^(\* \S+) (.*)$/
        Message.create(opts.merge nick: $1, line: $2)
      when /^(\* \S+)$/
        Message.create(opts.merge nick: $1, line: "")
      when /^--- join: (\S+) \(.*?\) joined #{opts[:channel]}$/
        Message.create(opts.merge nick: $1, opcode: 'join', line: "#{$1} has joined #{opts[:channel]}")
      when /^--- part: (\S+) left #{opts[:channel]}$/
        Message.create(opts.merge nick: $1, opcode: 'leave', line: "#{$1} has left #{opts[:channel]} []",
                       payload: "")
      when /^--- quit: (\S+) \((.*)\)$/
        Message.create(opts.merge nick: $1, opcode: 'quit', line: "#{$1} has quit [#{$2}]",
                       payload: $2)
      when /^--- nick: (\S+) -> (\S+)$/
        Message.create(opts.merge nick: $1, opcode: 'nick', line: "#{$1} is now known as #{$2}",
                       payload: $2)
      when /^--- topic: set to '(.*?)' by (\S+)$/
        Message.create(opts.merge nick: $2, opcode: 'topic',
                       line: "#{$2} changed the topic of #{opts[:channel]} to: #{$1}",
                       payload: $1)
      when /^--- topic: '(.*?)'$/, /^--- topic: set by/
        # ignore
      when /^--- kick: (\S+) was kicked by (\S+) \((.*)\)$/
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
