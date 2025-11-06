# frozen_string_literal: true

module Requestkit
  class CLI
    class << self
      def start(arguments)
        command = arguments[0]

        case command
        when "server", nil
          start_server with: arguments
        when "help", "--help", "-h"
          output_help
        else
          puts "Unknown command: #{command}"
          puts "Run `requestkit help` for usage information"

          exit 1
        end
      end

      private

      def start_server(with:)
        config = Config.new
        merge! config, with: with

        trap("INT") do
          puts "\n📦 Packing up the toolkit…"

          exit 0
        end

        Server.new(config).start
      end

      def output_help
        puts <<~HELP
          Requestkit - Local HTTP request toolkit

          Usage:
            requestkit [server] [options]
            requestkit help

          Options:
            -p, --port PORT              Port to run on (default: 4000)
            -s, --storage TYPE           Storage type: memory or file (default: memory)
            -d, --database-path PATH     Database file path (default: ~/.config/requestkit/requestkit.db)
            -h, --help                   Show this help

          Examples:
            requestkit
            requestkit server --port 8080
            requestkit server --storage file
            requestkit server --storage file --database-path ./my-project.db
        HELP
      end

      def merge!(config, with:)
        arguments = with

        config.port = extract(arguments, "--port", "-p").to_i if has?(arguments, "--port", "-p")
        config.storage = extract(arguments, "--storage", "-s") if has?(arguments, "--storage", "-s")
        config.database_path = extract(arguments, "--database-path", "-d") if has?(arguments, "--database-path", "-d")
      end

      def has?(arguments, *flags)
        flags.any? { arguments.include? it }
      end

      def extract(arguments, *flags)
        index = flags.map { arguments.index it }.compact.first

        arguments[index + 1]
      end
    end
  end
end
