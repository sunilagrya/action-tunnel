require 'socket'
require 'pry'
require 'rack/utils'
require 'rack/multipart'


class Server
  def initialize(socket_address, socket_port)
    @server_socket = TCPServer.open(socket_port, socket_address)
    @server        = @server_socket
    @clients       = {}
    puts 'Started server.........'
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
          if conn_name == 'hello'
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
    client_id = headers['Host'].split('.').first
    connect_to_client(method, path, body, client_id, conn, headers['Content-Type'])
  end

  def connect_to_client(method, path, body, client_id, conn, content_type)
    if @clients.keys.include?(client_id)
      client = @clients[client_id]
      client.puts(method)
      client.puts(path)
      client.puts(content_type || 'text/html')
      client.puts(body)
      client.puts("end")
      response = client.recvmsg.first
      respond_back(conn, 200, response, content_type)
    else
      respond_back(conn, 302, 'Server not found', content_type)
    end
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


end
