require 'socket'
require 'dotenv'
require 'securerandom'
require 'typhoeus'
require 'pry'
require 'socksify'

Dotenv.load


class Client
  def initialize(host = ENV['HOST'] || 'localhost', port = ENV['PORT'] || 8080, local_port = 3000)
    @host            = host
    @port            = port
    @socket          = TCPSocket.open(@host, port)
    @local_port      = local_port
    @name            =  'hello' #SecureRandom.hex(5)
    @request_object  = send_request
    @response_object = listen_response

    @request_object.join # will send the request to server
    @response_object.join # will receive response from server
  end

  def send_request
    puts "Established a connection with server..."
    puts parse_url
    puts "Your client to connected to port #{@local_port}"
    begin
      Thread.new do
        @socket.puts "CLIENT:#{@name}"
      end
    rescue IOError => e
      puts e.message
      # e.backtrace
      @socket.close
    end

  end

  def listen_response
    begin
      Thread.new do
        loop do
          method       = @socket.gets&.chomp
          path         = @socket.gets&.chomp
          content_type = @socket.gets&.chomp
          body         = []

          while line = @socket.gets
            break if line.strip == "end"
            body << line.strip
          end

          body = body.join
          puts "#{method} PATH: #{path} TYPE:#{content_type}"

          if method.is_a?(String) && path.is_a?(String)
            request = Typhoeus::Request.new(
                "127.0.0.1:#{@local_port}#{path}",
                method:  method.downcase.to_sym,
                body:    body,
                headers: {'Content-Type' => content_type}
            )
            res = request.run
            @socket.sendmsg res.response_body
          else
            @socket.sendmsg 'Not found'
          end

        end
      end
    rescue IOError => e
      puts e.message
      # e.backtrace
      @socket.close
    end
  end

  def parse_url
    if @host == 'localhost'
      "Your URL is http://#{@name}.#{@host}:#{@port}"
    else
      "Your URL is http://#{@name}.action-tunnel.ml"
    end
  end
end
Client.new
