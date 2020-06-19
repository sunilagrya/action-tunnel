require 'socket'
require 'pry'
require 'rack'
require 'rack/utils'
require 'rack/multipart'
require 'rack/lobster'


class Server
  def initialize(socket_port)
    @server_socket = TCPServer.new(socket_port)
    @server        = @server_socket
    @clients       = {}
    puts 'Started server.........'
    puts "Connection Live to port #{socket_port}"
    run
  end

  private

  def run
    loop do
      client_connection = @server_socket.accept
      Thread.start(client_connection) do |conn| # open thread for each accepted connection
        req = conn.gets
        unless req.is_a?(NilClass)
          conn_name, path = req.split
          if conn_name.start_with?('CLIENT') || conn_name.start_with?('PROXY')
            if conn_name.start_with?('PROXY')
              conn_name = conn.gets
            end
            puts conn_name
            conn_name = conn_name.split(':').last.strip
            client_request(conn, conn_name)
          else
            http_request(conn, conn_name, path)
          end
        end
      end
    end.join
  end

  def http_request(conn, method, path)
    puts 'http'
    headers = {}
    while line = conn.gets.split(' ', 2)
      break if line[0] == ""
      headers[line[0].chop] = line[1].strip
    end
    data      = conn.read(headers["Content-Length"].to_i)
    body      = parse_data(headers, data)
    client_id = headers['Host'].split('.').first.strip
    connect_to_client(method, path, body, client_id, conn, headers['Content-Type'])
  end

  def connect_to_client(method, path, body, client_id, conn, content_type)
    if @clients.keys.include?(client_id)
      begin
        puts "#{method} - #{path} - #{client_id} - #{content_type}"
        puts "Connection to #{client_id}"
        client = @clients[client_id]
        client.puts(method)
        client.puts(path)
        client.puts(content_type || get_content_type(path))
        client.puts(body)
        client.puts("end")
        response = client.recvmsg.first
        respond_back(conn, 200, response, content_type)
      rescue
        @clients.delete(client_id)
        puts "Failed to connect to client..."
        show_lobster(conn)
      end
    else
      puts "No client found in the name #{client_id}"
      puts "Other client name are #{@clients.keys.join(',')}"
      show_lobster(conn)
    end
  end

  def show_lobster(conn)
    arr  = Rack::Lobster.new.call('REQUEST_METHOD' => 'GET')
    data = arr[2][0..3].join.gsub('Lobstericious', 'Action Tunnel')
    res  = "HTTP/1.1 #{200}\r\n" +
        "Content-Type: #{'text/html'}\r\n" +
        "Content-Length: #{data.size}\r\n" +
        "\r\n" +
        "#{data}\r\n"
    conn.write(res)
    conn.close
  end

  def respond_back(conn, status_code, data, content_type)
    res = "HTTP/1.1 #{status_code}\r\n" +
        "Content-Type: #{content_type || 'text/html'}\r\n" +
        "Content-Length: #{data.size}\r\n" +
        "\r\n" +
        "#{data}\r\n"
    conn.write(res)
    conn.close
  end

  def client_request(conn, conn_name)
    puts 'client_request'
    if conn_name.is_a?(NilClass) || @clients.keys.include?(conn_name) # avoid connection if user exits
      conn.puts "This username already exist"
      conn.puts "quit"
    else
      puts "Connection established #{conn_name} => #{conn}"
      @clients[conn_name] = conn
    end
  end

  def parse_data(headers, data)
    return data if headers['Content-Type'].is_a?(NilClass)
    if headers['Content-Type'].match?('multipart/form-data')
      boundary = Rack::Multipart::Parser.parse_boundary(headers['Content-Type'])
      data.chomp.gsub(boundary, '').gsub("Content-Disposition: form-data; name=", '').split('--').join.strip
    else
      data
    end
  end

  def get_content_type(path)
    if path.end_with?('.js')
      'application/javascript'
    elsif path.end_with?('.css')
      'text/css'
    else
      'text/html'
    end
  end


end

Server.new(ENV['PORT'] || 8080)
