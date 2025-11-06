# frozen_string_literal: true

require "fileutils"
require "sqlite3"

module Requestkit
  class Storage
    def initialize(config)
      database_path = (config.storage == "file") ? config.database_path : ":memory:"

      if config.storage == "file"
        FileUtils.mkdir_p(File.dirname(config.database_path))
      end

      @db = SQLite3::Database.new(database_path)
      @db.results_as_hash = true

      setup!
    end

    def store(namespace:, method:, path:, request:, timestamp:, direction: "inbound", response: nil, status: nil, parent_id: nil)
      @db.execute(
        "INSERT INTO requests (namespace, direction, method, path, request, response, status, parent_id, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [namespace, direction, method, path, request, response, status, parent_id, timestamp]
      )
    end

    def all = @db.execute("SELECT * FROM requests ORDER BY id DESC")

    def namespaces = @db.execute("SELECT DISTINCT namespace FROM requests ORDER BY namespace").map { |row| row["namespace"] }

    def by_namespace(namespace) = @db.execute("SELECT * FROM requests WHERE namespace = ? ORDER BY id DESC", [namespace])

    def clear = @db.execute("DELETE FROM requests")

    private

    def setup!
      @db.execute <<~SQL
        CREATE TABLE IF NOT EXISTS requests (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          namespace TEXT NOT NULL,
          direction TEXT NOT NULL DEFAULT 'inbound',
          method TEXT NOT NULL,
          path TEXT NOT NULL,
          request TEXT NOT NULL,
          response TEXT,
          status INTEGER,
          parent_id INTEGER,
          timestamp TEXT NOT NULL
        )
      SQL
    end
  end
end
