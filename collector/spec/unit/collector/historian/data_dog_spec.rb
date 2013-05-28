require File.expand_path("../../../spec_helper", File.dirname(__FILE__))

describe Collector::Historian::DataDog do
  describe "initialization" do
    it "configures DataDog api" do
      Dogapi::Client.should_receive(:new).with("API_KEY", "APPLICATION_KEY")

      described_class.new("API_KEY", "APPLICATION_KEY")
    end
  end

  describe "sending data to DataDog" do
    let(:dog_client) { double("DataDog Client") }
    before do
      Dogapi::Client.should_receive(:new).and_return(dog_client)
      ::Collector::Config.stub(:deployment_name).and_return("dev114cw")
    end

    it "converts the properties hash into a DataDog point" do
      time = Time.now
      datadog_historian = described_class.new("API_KEY", "APPLICATION_KEY")

      tags = %w[
        job:Test
        index:1
        component:unknown
        service_type:unknown
        tag:value
        foo:bar
        foo:baz
      ]
      dog_client.should_receive(:emit_points)
        .with("cf.collector.some_metric.some_key", [[Time.at(time), 2]], tags: tags)

      datadog_historian.send_data({
        key: "some_metric.some_key",
        timestamp: time,
        value: 2,
        tags: {
          job: "Test",
          index: 1,
          component: "unknown",
          service_type: "unknown",
          tag: "value",
          foo: %w(bar baz)
        }
      })
    end
  end
end