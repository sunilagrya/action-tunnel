require 'daemons'

pwd  = File.dirname(File.expand_path(__FILE__))
file = pwd + '/server.rb'

Daemons.run_proc('action-tunnel', no_pidfiles: true, multiple: true) do
  exec "ruby #{file}"
end

