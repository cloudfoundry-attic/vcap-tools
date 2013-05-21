require File.expand_path("../../spec_helper", File.dirname(__FILE__))

describe Collector::Historian do
  let(:historian) { Collector::Historian.build }

  before do
    EventMachine.stub(:connect)
    Collector::Config.configure(config_override)
  end

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

    it "builds a historian that logs to TSDB" do
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
      historian = Collector::Historian.build
      historian.should respond_to :send_data
    end
  end

  describe "configuring with datadog data" do
    let(:config_override) do
      {
          "intervals" => {},
          "logging" => {},
          "datadog" => {
              "api_key" => "DATADOG_API_KEY",
              "application_key" => "DATADOG_APPLICATION_KEY"
          }
      }
    end

    before do
      Dogapi::Client.stub(:new)
      Collector::Config.configure(config_override)
    end

    it "builds a historian that logs to DataDog" do
      historian = Collector::Historian.build
      historian.should respond_to :send_data
    end
  end

  describe "configuring with all" do
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
          },
          "datadog" => {
              "api_key" => "DATADOG_API_KEY",
              "application_key" => "DATADOG_APPLICATION_KEY"
          }
      }
    end

    before do
      Collector::Config.configure(config_override)
    end

    it "builds a historian that logs to both services" do
      AWS.should_receive(:config).with(access_key_id: "AWS_ACCESS_KEY12345", secret_access_key: "AWS_SECRET_ACCESS_KEY98765")
      EventMachine.should_receive(:connect).with("localhost", 4242, Collector::TsdbConnection)
      Dogapi::Client.should_receive(:new).with("DATADOG_API_KEY", "DATADOG_APPLICATION_KEY")

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
          },
          "datadog" => {
              "api_key" => "DATADOG_API_KEY",
              "application_key" => "DATADOG_APPLICATION_KEY"
          }
      }
    end

    let(:connection) { double('Connection') }
    let(:cloud_watch) { double('Cloud Watch') }
    let(:dog_client) { double('DataDog Client') }

    before do
      AWS.stub(:config)
      AWS::CloudWatch.stub(:new).and_return(cloud_watch)
      EventMachine.stub(:connect).and_return(connection)
      Dogapi::Client.stub(:new).and_return(dog_client)
    end

    context "when one of the historians fail" do
      before { connection.should_receive(:send_data).and_raise("FAIL") }

      it "should still send data to the other historians" do
        cloud_watch.should_receive(:put_metric_data)
        dog_client.should_receive(:emit_points)

        expect { historian.send_data({tags: {}}) }.to_not raise_error
      end
    end
  end
end