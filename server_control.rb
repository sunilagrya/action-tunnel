require 'daemons'

pwd  = File.dirname(File.expand_path(__FILE__))
file = pwd + '/server.rb'

Daemons.run_proc(
    'action-tunnel', # name of daemon
    :no_pidfiles   => true,
    :log_output => true
) do
  exec "ruby #{file}"
end

