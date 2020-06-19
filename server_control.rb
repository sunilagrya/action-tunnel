require 'daemons'
require 'dotenv'

Dotenv.load

pwd  = File.dirname(File.expand_path(__FILE__))
file = pwd + '/server.rb'

Daemons.run_proc('action-tunnel', no_pidfiles: true, log_output: true, log_dir: "#{pwd}/tmp") do
  exec "ruby #{file}"
end

