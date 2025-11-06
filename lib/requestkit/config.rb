# frozen_string_literal: true

require "yaml"

module Requestkit
  class Config
    attr_accessor :port, :storage, :database_path, :default_namespace

    def initialize
      @port = 4000
      @storage = "memory"
      @database_path = File.join(Dir.home, ".config", "requestkit", "requestkit.db")
      @default_namespace = "default"

      load!
    end

    private

    def load!
      merge! user_config if File.exist? user_config
      merge! local_config if File.exist? local_config
    end

    def merge!(path)
      data = YAML.load_file(path)

      @port = data["port"] if data["port"]
      @storage = data["storage"] if data["storage"]
      @database_path = data["database_path"] if data["database_path"]
      @default_namespace = data["default_namespace"] if data["default_namespace"]
    end

    def user_config = File.join(Dir.home, ".config", "requestkit", "config.yml")

    def local_config = File.join(Dir.pwd, ".requestkit.yml")
  end
end
