require './viewer'

Sinatra::Base.set :run, false
Sinatra::Base.set :environment, ENV['RACK_ENV']

run Sinatra::Application