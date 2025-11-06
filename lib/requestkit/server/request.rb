# frozen_string_literal: true

require "async/http/client"
require "openssl"

module Requestkit
  class Server
    class Request
      class << self
        def send(database:, namespace:)
          request_data = {
            headers: {"Content-Type" => "application/json", "User-Agent" => "Requestkit/#{Requestkit::VERSION}"},
            body: '{"test": "data"}'
          }

          endpoint = ssl_endpoint_for("https://httpbin.org/post")
          client = Async::HTTP::Client.new(endpoint)

          response = client.post("/post", request_data[:headers], request_data[:body])
          response_data = {
            headers: response.headers.to_h,
            body: response.body&.read || ""
          }

          client.close

          database.store(
            namespace: namespace,
            method: "POST",
            path: "https://httpbin.org/post",
            request: request_data.to_json,
            response: response_data.to_json,
            status: response.status,
            direction: "outbound",
            timestamp: Time.now.iso8601
          )
        end

        private

        def ssl_endpoint_for(url)
          endpoint = Async::HTTP::Endpoint.parse(url)
          ssl_context = OpenSSL::SSL::SSLContext.new
          ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE

          endpoint.with(ssl_context: ssl_context)
        end
      end
    end
  end
end
