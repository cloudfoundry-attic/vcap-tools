require 'spec_helper'
#require 'collector/handlers/health_manager'

describe "Collector::Handler::HealthManager" do
  before do
    Collector::Handler.handler_map.clear
    Collector::Handler.instance_map.clear
  end

  let(:total_users) { 687 }
  let(:varz) do
    {
      "running" => {
        "flapping_instances" => 11,
        "missing_instances" => 13,
        "running_instances" => 88,
        "crashes" => 0,
        "apps" => 98
      },
      "total_users" => total_users,
      "total" => {
        "started_memory" => 32000,
        "memory" => 176000,
        "started_instances" => 112,
        "instances" => 1193,
        "started_apps" => 98,
        "apps" => 150
      }
    }
  end
  let(:handler) { Collector::Handler::HealthManager.new(nil, nil) }

  it "sends metrics for every entry" do
    context = Collector::HandlerContext.new(nil, nil, varz)
    handler.should_receive(:send_metric).with("running.crashes", 0, context)
    handler.should_receive(:send_metric).with("running.running_apps", 98, context)
    handler.should_receive(:send_metric).with("total.apps", 150, context)
    handler.should_receive(:send_metric).with("total_users", 687, context)

    handler.should_receive(:send_metric).exactly(12 - 4).times

    handler.process(context)
  end

  describe "user rate metric" do
    it "sends the number of new users since the last varz check" do
      handler.should_receive(:send_metric).twice.with("total_users", anything, anything)
      handler.should_receive(:send_metric).once.with("user_rate", 50, anything)

      varz = { "total_users" => 100 }
      context = Collector::HandlerContext.new(nil, 0, varz)
      handler.process(context)

      varz = { "total_users" => 150 }
      context = Collector::HandlerContext.new(nil, 1, varz)
      handler.process(context)

    end

    context "when the collector has no prior information about the number of users (i.e., when it's started up)" do

      it "doesn't send a user rate metric" do
        varz = { "total_users" => 123 }
        context = Collector::HandlerContext.new(nil, nil, varz)

        handler.should_not_receive(:send_metric).with("user_rate", anything, context)
        handler.process(context)
      end
    end
  end
end
