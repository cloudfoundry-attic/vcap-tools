# Copyright (c) 2009-2012 VMware, Inc.

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

RSpec.configure do |c|
  c.before do
    EventMachine.should_receive(:defer).any_number_of_times.and_yield
  end
end


def create_fake_collector
  Collector::Config.tsdb_host = "dummy"
  Collector::Config.tsdb_port = 14242
  Collector::Config.nats_uri = "nats://foo:bar@nats-host:14222"

  EventMachine.should_receive(:connect).
    with("dummy", 14242, Collector::TsdbConnection)

  nats_connection = mock(:NatsConnection)
  NATS.should_receive(:connect).
    with(:uri => "nats://foo:bar@nats-host:14222").
    and_return(nats_connection)

  yield Collector::Collector.new, nats_connection
end
