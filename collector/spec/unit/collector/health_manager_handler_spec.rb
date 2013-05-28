require 'spec_helper'
#require 'collector/handlers/health_manager'

describe "Collector::Handler::HealthManager" do
  it "sends metrics for every entry" do
    #    Collector::Handler::HealthManager.should_receive(:register).and_return(nil)

    create_fake_collector do

      varz = {
        "running" => {
          "flapping_instances" => 11,
          "missing_instances" => 13,
          "running_instances" => 88,
          "crashes" => 0,
          "apps" => 98
        },
        "total_users" => 687,
        "total" => {
          "started_memory" => 32000,
          "memory" => 176000,
          "started_instances" => 112,
          "instances" => 1193,
          "started_apps" => 98,
          "apps" => 150
        }
      }

      handler =  Collector::Handler::HealthManager.new(nil, nil, nil, nil, varz)

      handler.should_receive(:send_metric).with("running.crashes", 0)
      handler.should_receive(:send_metric).with("running.running_apps", 98)
      handler.should_receive(:send_metric).with("total.apps", 150)
      handler.should_receive(:send_metric).with("total_users", 687)

      handler.should_receive(:send_metric).exactly(12 - 4).times

      handler.process
      Collector::Handler.handler_map = {}
    end
  end
end
