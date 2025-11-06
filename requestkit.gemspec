# frozen_string_literal: true

require_relative "lib/requestkit/version"

Gem::Specification.new do |spec|
  spec.name = "requestkit"
  spec.version = Requestkit::VERSION
  spec.authors = ["Rails Designer Developers"]
  spec.email = ["devs@railsdesigner.com"]

  spec.summary = "Local HTTP request toolkit"
  spec.description = "Capture webhooks and send HTTP requests locally. Think webhook.site meets Postman, but living on your machine where it belongs."
  spec.homepage = "https://requestkit.railsdesigner.com/"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Rails-Designer/requestkit"

  spec.files = Dir["lib/**/*", "exe/*", "README.md", "LICENSE"]

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { File.basename(it) }

  spec.required_ruby_version = ">= 3.4.0"

  spec.add_dependency "async-http", "~> 0.90"
  spec.add_dependency "sqlite3", "~> 2.7"
end
