$: << File.join(File.dirname(__FILE__), 'lib')

require 'irclogger'
require 'irclogger/viewer'

IrcLogger::Channel.listen

run IrcLogger::Viewer