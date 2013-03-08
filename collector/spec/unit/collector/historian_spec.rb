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
      historian.should respond_to :send_data
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
      AWS.should_receive :config
      Collector::Config.configure(config_override)
    end

    it "builds a historian that logs to cloud watch" do
      historian = described_class.build
      historian.should respond_to :send_data
    end
  end

  describe "configuring with both" do
    let(:config_override) do
      {
          "intervals" => {},
          "logging" => {},
          'aws_cloud_watch' => {
              'access_key_id' => "AWS_ACCESS_KEY12345",
              'secret_access_key' => "AWS_SECRET_ACCESS_KEY98765"
          },
          'tsdb' => {
              'port' => 4242,
              'host' => "localhost"
          }
      }
    end

    before do
      Collector::Config.configure(config_override)
    end

    it "builds a historian that logs to both services" do
      AWS.should_receive(:config).with(access_key_id: "AWS_ACCESS_KEY12345", secret_access_key: "AWS_SECRET_ACCESS_KEY98765")
      EventMachine.should_receive(:connect).with("localhost", 4242, Collector::TsdbConnection)

      historian = described_class.build
      historian.should respond_to :send_data
    end
  end

  describe "when sending data" do
    let(:config_override) do
      {
          "intervals" => {},
          "logging" => {},
          'aws_cloud_watch' => {
              'access_key_id' => "AWS_ACCESS_KEY12345",
              'secret_access_key' => "AWS_SECRET_ACCESS_KEY98765"
          },
          'tsdb' => {
              'port' => 4242,
              'host' => "localhost"
          }
      }
    end

    let(:connection) { double('Connection') }
    let(:cloud_watch) { double('Cloud Watch') }

    before do
      AWS.should_receive(:config)
      AWS::CloudWatch.should_receive(:new).and_return(cloud_watch)

      EventMachine.should_receive(:connect).and_return(connection)
    end

    context "when one of the historians fail" do
      before do
        connection.should_receive(:send_data).and_raise("FAIL")
      end

      it "should still send data to the other historians" do
        cloud_watch.should_receive(:put_metric_data)

        historian = described_class.build
        expect { historian.send_data({tags: {}}) }.to_not raise_error
      end
    end
  end
end