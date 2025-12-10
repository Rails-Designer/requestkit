# frozen_string_literal: true

require "erb"

require "requestkit/server/request"

module Requestkit
  class Server
    class Render
      class << self
        def html(request, database, config)
          params = query_params(from: request.path)
          selected_namespace = params["namespace"] unless params["namespace"] && params["namespace"].empty?

          context = {
            requests: selected_namespace ? database.by_namespace(selected_namespace) : database.all,
            namespaces: database.namespaces,
            saved_requests: Request.all_saved,
            selected_namespace: selected_namespace
          }

          template = ERB.new(File.read(File.join(__dir__, "..", "templates", "index.html.erb")))
          html = template.result_with_hash(context)

          Protocol::HTTP::Response[200, {"content-type" => "text/html"}, [html]]
        end

        def css
          css_path = File.join(__dir__, "..", "templates", "index.css")
          css_content = File.read(css_path)

          Protocol::HTTP::Response[200, {"content-type" => "text/css"}, [css_content]]
        end

        private

        def query_params(from:)
          return {} unless from.include?("?")

          query_string = from.split("?", 2).last
          query_string.split("&").each_with_object({}) do |pair, hash|
            key, value = pair.split("=", 2)
            hash[key] = value
          end
        end
      end
    end
  end
end
