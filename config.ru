require 'sinatra'

Sinatra::Base.set :run, false
Sinatra::Base.set :environment, ENV['RACK_ENV']

require './irclogger'
run Sinatra::Application