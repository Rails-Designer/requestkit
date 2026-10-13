# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"
require "minitest/mock"

class TestRequest < Minitest::Test
  FakeResponse = Struct.new(:status, :headers, :body)

  class FakeClient
    attr_reader :calls

    def initialize = @calls = []

    def post(path, headers, body)
      @calls << path
      FakeResponse.new(200, {}, nil)
    end
    alias_method :get, :post

    def close = nil
  end

  def setup
    @dir = Dir.mktmpdir
    @previous_dir = Dir.pwd
    Dir.chdir(@dir)
    @database = Requestkit::Storage.new(Requestkit::Config.new.tap { it.storage = "memory" })
  end

  def teardown
    Dir.chdir(@previous_dir)
    FileUtils.rm_rf(@dir)
  end

  def test_sends_the_query_string_of_the_saved_url
    assert_equal ["/hooks/github?token=abc&x=1"], sent_paths("http://localhost:3000/hooks/github?token=abc&x=1")
  end

  def test_sends_root_for_a_url_without_a_path
    assert_equal ["/"], sent_paths("http://localhost:3000")
  end

  private

  def sent_paths(url)
    save_request(url)
    client = FakeClient.new

    Async::HTTP::Client.stub(:new, client) do
      assert Requestkit::Server::Request.send(database: @database, namespace: "github", name: "push")
    end

    client.calls
  end

  def save_request(url)
    path = File.join(".requestkit", "requests", "github", "push.json")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, JSON.generate("method" => "POST", "url" => url, "headers" => {}, "body" => "{}"))
  end
end
