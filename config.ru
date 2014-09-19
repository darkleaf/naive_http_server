#\ -s my

require 'rubygems'
require 'bundler'
Bundler.require



require 'socket'
require "http/parser"
require 'rack/rewindable_input'





class Server
  attr_accessor :app, :server, :parser

  def initialize(app)
    @app = app
    @server = TCPServer.new 2000
    @parser = Http::Parser.new


    parser.on_message_complete = proc do |env|
      # Headers and body is all parsed
      #p env
      p parser.request_url
      #puts "Done!"
    end
  end









  def start
    loop do
      client = server.accept


      while line = client.gets # Read lines from socket
        parser << line
        break if line == "\r\n"
      end


      status, headers, body = app.call(get_env)

      client.print "Status: #{status}\r\n"
      headers.each { |k, vs|
        vs.split("\n").each { |v|
          client.print "#{k}: #{v}\r\n"
        }
      }
      client.print "\r\n"


      body.each do |chunk|
        client.puts chunk
      end

      client.close
    end
  end

  def get_env
    {
        'REQUEST_METHOD' => parser.http_method,
        'SCRIPT_NAME' => '',
        'PATH_INFO' => parser.request_url, #full name. its wrong!
        'QUERY_STRING' => '',
        'SERVER_NAME' => 'localhost',
        'SERVER_PORT' => '2000',
        "rack.version" => Rack::VERSION,
        "rack.input" => Rack::RewindableInput.new($stdin),
        "rack.errors" => $stderr,

        "rack.multithread" => false,
        "rack.multiprocess" => true,
        "rack.run_once" => true,

        "rack.url_scheme" => "http"
    }
  end
end



module Rack
  module Handler
    class My
      def self.run(app, options={})
        server = ::Server.new(app)
        server.start
      end
    end

    register :my, My
  end
end








run ->(env){ ['200', {'Content-Type' => 'text/html'}, ['A barebones rack app.']] }
