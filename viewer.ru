$: << File.join(File.dirname(__FILE__), 'lib')

require 'irclogger'
require 'irclogger/viewer'

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

IrcLogger::Channel.listen

run IrcLogger::Viewer
