require File.expand_path("../../spec_helper", File.dirname(__FILE__))

describe Collector::Historian do
  describe "setting up a historian with tsdb data" do
    let(:config_override) do
      {
          "intervals" => {},
          "logging" => {},
          'tsdb' => {
              'port' => 4242,
              'host' => "localhost"
          }
      }
    end

    before do
      EventMachine.stub(:connect)
      Collector::Config.configure(config_override)
    end

    it "builds a historian that logs to TSDB" do
      historian = described_class.build
      historian.should be_a_kind_of(Collector::Historian::Tsdb)
    end
  end

  describe "configuring with aws data" do
    let(:config_override) do
      {
          "intervals" => {},
          "logging" => {},
          'aws_cloud_watch' => {
              'access_key_id' => "AWS_ACCESS_KEY12345",
              'secret_access_key' => "AWS_SECRET_ACCESS_KEY98765"
          }
      }
    end

    before do
      Collector::Config.configure(config_override)
    end

    it "builds a historian that logs to cloud watch" do
      historian = described_class.build
      historian.should be_a_kind_of(Collector::Historian::CloudWatch)
    end
  end
end