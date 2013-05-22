require 'spec_helper'

describe Collector::Handler::Router do
  describe "#is_healthy?" do
    let(:handler) { Collector::Handler::Router.new(nil, nil, nil, nil) }

    it "is true for health: ok json" do
      expect(handler.is_healthy?('{"health":"ok"}')).to eq(true)
      expect(handler.is_healthy?('{ "health" : "ok" }')).to eq(true)
    end

    it "is false for non-json" do
      expect(handler.is_healthy?("it's okay")).to eq(false)
    end
  end
end