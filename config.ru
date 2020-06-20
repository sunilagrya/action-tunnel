require './server'
run Server.new(ENV["PORT"] || 8080, "localhost")
