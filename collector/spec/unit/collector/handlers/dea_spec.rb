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
end