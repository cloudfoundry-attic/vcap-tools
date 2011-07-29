$:.unshift(File.expand_path("../lib", File.dirname(__FILE__)))

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", File.dirname(__FILE__))
require "rubygems"
require "bundler"
Bundler.setup(:default, :test)

require "rspec/core"

require "collector"

Collector::Config.configure({
  "logging" => {"level" => ENV["DEBUG"] ? "debug2" : "fatal"},
  "tsdb" => {},
  "intervals" => {}
})

