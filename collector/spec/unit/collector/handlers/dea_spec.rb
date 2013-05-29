require 'spec_helper'

describe Collector::Handler::Dea do

  describe "#additional_tags" do
    it "tags metrics with the stack type" do
      collector = Collector::Handler::Dea.new(nil, nil, nil, nil, {"stacks" => ["Linux", "Windows"]})

      # note stacks in the varz becomes stack singular in the tags
      collector.additional_tags.should == {
        stack: ["Linux", "Windows"]
      }
    end
  end

  describe "process" do
    it "sends the can_stage metric" do
      varz = {
        "can_stage" => 1
      }

      handler = Collector::Handler::Dea.new(nil, nil, nil, nil, varz)
      handler.should_receive(:send_metric).with("can_stage", 1)
      handler.process
    end
  end
end