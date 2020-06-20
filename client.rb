require 'socket'
require 'securerandom'
require 'typhoeus'
require 'pry'
require 'socksify'


class Client
  def initialize(socket)
    @socket          = socket
    @name            = 'hello'
    @request_object  = send_request
    @response_object = listen_response

    @request_object.join # will send the request to server
    @response_object.join # will receive response from server
  end

  def send_request
    puts "Established a connection with server #{@name}..."
    begin
      Thread.new do
        @socket.puts @name
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
          puts content_type

          if method.is_a?(String) && path.is_a?(String)
            request = Typhoeus::Request.new(
                "localhost:3000#{path}",
                method:  method.downcase.to_sym,
                body:    body,
                headers: {'Content-Type' => content_type}
            )
            res     = request.run
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

  def parse_data

  end
end

# proxy_uri = URI.parse("socks://#{FIXIE_SOCKS_HOST}")
# TCPSocket::socks_server = proxy_uri.host
# TCPSocket::socks_port = proxy_uri.port
# TCPSocket::socks_username = proxy_uri.user
# TCPSocket::socks_password = proxy_uri.password

socket = TCPSocket.new('sleepy-wave-89623.herokuapp.com', 80)
Client.new(socket)
