# frozen_string_literal: true

require "async"
require "async/http/endpoint"
require "async/http/server"
require "protocol/http/response"

require "requestkit/server/render"
require "requestkit/server/request"

Console.logger.level = :error

module Requestkit
  class Server
    def initialize(config)
      @config = config
      @port = config.port
      @db = Storage.new(config)
      @clients = []
    end

    def start
      puts "📦 Requestkit starting on http://localhost:#{@port}"
      puts "Press Ctrl+C to stop"

      endpoint = Async::HTTP::Endpoint.parse("http://localhost:#{@port}")

      Async do
        Async::HTTP::Server.new(method(:route), endpoint).run
      end
    end

    private

    def route(request)
      path = request.path.split("?").first
      method = request.method

      return Protocol::HTTP::Response[204, {}, []] if path == "/favicon.ico"
      return stream! if path == "/events" && method == "GET"

      case [path, method]
      when ["/", "GET"]
        Render.html(request, @db, @config)
      when ["/send", "POST"]
        query_parameters = Render.send(:query_params, from: request.path)
        namespace = query_parameters["namespace"] || "test"
        name = query_parameters["name"] || "default"

        success = Request.send(database: @db, namespace: namespace, name: name)

        if success
          notify!
          Protocol::HTTP::Response[303, {"location" => "/"}, []]
        else
          Protocol::HTTP::Response[400, {"content-type" => "text/plain"}, ["Failed to send request"]]
        end
      when ["/index.css", "GET"]
        Render.css
      when ["/clear", "POST"]
        @db.clear

        Protocol::HTTP::Response[303, {"location" => "/"}, []]
      else
        capture(request)

        Protocol::HTTP::Response[200, {"content-type" => "text/plain"}, ["OK"]]
      end
    end

    def capture(request)
      request_data = {
        headers: request.headers.to_h,
        body: request.body&.read || ""
      }

      namespace = extract_namespace(from: request.path)

      @db.store(
        namespace: namespace,
        method: request.method,
        path: request.path,
        request: request_data.to_json,
        direction: "inbound",
        timestamp: Time.now.iso8601
      )

      notify!
    end

    def stream!
      body = Protocol::HTTP::Body::Writable.new
      @clients << body

      Protocol::HTTP::Response[
        200,
        {"content-type" => "text/event-stream", "cache-control" => "no-cache", "connection" => "keep-alive"},
        body
      ]
    end

    def extract_namespace(from:)
      path = from.split("?").first
      segments = path.split("/").reject(&:empty?)

      segments.first || @config.default_namespace
    end

    def notify!
      latest = @db.all.first
      return unless latest

      data = JSON.generate(latest)
      @clients.each do |client|
        client.write("data: #{data}\n\n")
      rescue Errno::EPIPE, IOError
        @clients.delete(client)
      end
    end
  end
end
