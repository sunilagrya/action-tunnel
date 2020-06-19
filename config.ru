require './server'
Server.new(ENV["PORT"] || 8080, "localhost")
