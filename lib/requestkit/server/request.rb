# frozen_string_literal: true

require "async/http/client"
require "openssl"
require "json" # not needed?

module Requestkit
  class Server
    class Request
      class << self
        def send(database:, namespace:, name:)
          request_definition = load_request(namespace: namespace, name: name)

          unless request_definition
            return false
          end

          request_data = {
            headers: request_definition["headers"].merge({"User-Agent" => "Requestkit/#{Requestkit::VERSION}"}),
            body: request_definition["body"]
          }

          url = request_definition["url"]
          method = request_definition["method"].downcase

          endpoint = ssl_endpoint_for(url)
          client = Async::HTTP::Client.new(endpoint)

          response = client.send(method, URI(url).path, request_data[:headers], request_data[:body])
          response_data = {
            headers: response.headers.to_h,
            body: response.body&.read || ""
          }

          client.close

          database.store(
            namespace: namespace,
            method: method.upcase,
            path: url,
            request: request_data.to_json,
            response: response_data.to_json,
            status: response.status,
            direction: "outbound",
            timestamp: Time.now.iso8601
          )

          true
        rescue => error
          puts "Error sending request: #{error.message}"

          false
        end

        def all_saved
          {}.tap do |requests|
            [local_requests_dir, user_requests_dir].each do |base_dir|
              next unless Dir.exist?(base_dir)

              Dir.glob(File.join(base_dir, "*", "*.json")).each do |file_path|
                namespace = File.basename(File.dirname(file_path))
                name = File.basename(file_path, ".json")

                begin
                  definition = JSON.parse(File.read(file_path))

                  unless definition["method"] && definition["url"]
                    next
                  end

                  requests[namespace] ||= []
                  requests[namespace] << {
                    "name" => name,
                    "method" => definition["method"],
                    "url" => definition["url"]
                  }
                rescue JSON::ParserError
                  next
                end
              end
              # Dir.glob(File.join(base_dir, "*", "*.json")).each do |file_path|
              #   namespace = File.basename(File.dirname(file_path))
              #   name = File.basename(file_path, ".json")
              #   definition = JSON.parse(File.read(file_path))

              #   requests[namespace] ||= []
              #   requests[namespace] << {
              #     "name" => name,
              #     "method" => definition["method"],
              #     "url" => definition["url"]
              #   }
              # end
            end
          end
        end

        private

        # def load_request(namespace:, name:)
        #   [local_request_path(namespace, name), user_request_path(namespace, name)].each do |path|
        #     return JSON.parse(File.read(path)) if File.exist?(path)
        #   end

        #   puts "Request file not found: #{namespace}/#{name}"
        #   nil
        # end
        def load_request(namespace:, name:)
          [local_request_path(namespace, name), user_request_path(namespace, name)].each do |path|
            if File.exist?(path)
              definition = JSON.parse(File.read(path))

              unless definition["method"] && definition["url"]
                puts "Invalid request file #{namespace}/#{name}: missing `method` or `url`"

                return nil
              end

              return definition
            end
          end

          puts "Request file not found: #{namespace}/#{name}"

          nil
        rescue JSON::ParserError => error
          puts "Invalid JSON in #{namespace}/#{name}: #{error.message}"

          nil
        end

        def ssl_endpoint_for(url)
          endpoint = Async::HTTP::Endpoint.parse(url)
          ssl_context = OpenSSL::SSL::SSLContext.new
          ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE

          endpoint.with(ssl_context: ssl_context)
        end

        def local_request_path(namespace, name) = File.join(local_requests_dir, namespace, "#{name}.json")

        def user_request_path(namespace, name) = File.join(user_requests_dir, namespace, "#{name}.json")

        def local_requests_dir = File.join(Dir.pwd, ".requestkit", "requests")

        def user_requests_dir = File.join(Dir.home, ".config", "requestkit", "requests")
      end
    end
  end
end
