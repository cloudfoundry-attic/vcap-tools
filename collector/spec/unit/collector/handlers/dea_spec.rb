require 'spec_helper'

describe Collector::Handler::Dea do

  describe "#additional_tags" do
    it "tags metrics with the stack type" do
      context = Collector::HandlerContext.new(nil, nil, {"stacks" => ["Linux", "Windows"]})
      handler = Collector::Handler::Dea.new(nil, nil)

      # note stacks in the varz becomes stack singular in the tags
      handler.additional_tags(context).should == {
        stack: ["Linux", "Windows"]
      }
    end
  end

  describe "process" do
    it "sends the can_stage metric" do
      varz = {
        "can_stage" => 1
      }

      context = Collector::HandlerContext.new(nil, nil, varz)
      handler = Collector::Handler::Dea.new(nil, nil)
      handler.should_receive(:send_metric).with("can_stage", 1, context)
      handler.process(context)
    end
  end
end