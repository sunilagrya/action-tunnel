require './server'
Server.new(ENV.fetch("PORT") || 8080, "localhost")
