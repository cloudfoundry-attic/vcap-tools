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
    let(:handler) { Collector::Handler::Dea.new(nil, nil) }

    before do
      handler.stub(:send_metric)
    end

    it "sends the can_stage metric" do
      varz = {
        "can_stage" => 1
      }

      context = Collector::HandlerContext.new(nil, nil, varz)
      handler.should_receive(:send_metric).with("can_stage", 1, context)
      handler.process(context)
    end

    it "sends the reservable stagers metric" do
      varz = {
        "reservable_stagers" => 34
      }

      context = Collector::HandlerContext.new(nil, nil, varz)
      handler.should_receive(:send_metric).with("reservable_stagers", 34, context)
      handler.process(context)
    end

    it "sends the resource availability metrics" do
      varz = {
        "available_memory_ratio" => 0.363,
        "available_disk_ratio" => 0.657
      }

      context = Collector::HandlerContext.new(nil, nil, varz)
      handler.should_receive(:send_metric).with("available_disk_ratio", 0.657, context)
      handler.should_receive(:send_metric).with("available_memory_ratio", 0.363, context)
      handler.process(context)
    end
  end
end
