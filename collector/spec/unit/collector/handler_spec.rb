# Copyright (c) 2009-2012 VMware, Inc.

require File.expand_path("../../spec_helper", File.dirname(__FILE__))

describe Collector::Handler do

  describe :register do
    after(:each) do
      Collector::Handler.handler_map.clear
    end

    it "should register varz handler plugins" do
      test_handler = Class.new(Collector::Handler) do
        register "Test"
      end

      Collector::Handler.handler_map.should == {"Test" => test_handler}
    end


    it "should fail to register multiple handlers for a single job" do
      Class.new(Collector::Handler) do
        register "Test"
      end

      lambda {
        Class.new(Collector::Handler) do
          register "Test"
        end
      }.should raise_exception "Job: Test already registered"
    end
  end

  describe :handler do
    after(:each) do
      Collector::Handler.handler_map.clear
    end

    it "should return the registered varz handler plugin" do
      test_handler = Class.new(Collector::Handler) do
        register "Test"
      end

      Collector::Handler.handler(nil, "Test", nil, nil).
          should be_kind_of(test_handler)
    end

    it "should return the default handler when none registered" do
      Collector::Handler.handler(nil, "Test", nil, nil).
          should be_kind_of(Collector::Handler)
    end
  end

  describe :send_metric do
    it "should send the metric to the Historian" do
      historian = mock('Historian')
      historian.should_receive(:send_data).
          with({key: "some_key",
                timestamp: 10000,
                value: 2,
                tags: {index: 1, job: "Test", tag: "value"}})

      handler = Collector::Handler.handler(historian, "Test", 1, 10000)
      handler.send_metric("some_key", 2, {:tag => "value"})
    end

    context "TSDB" do
      before do
        connection = double('EventMachine')
        EventMachine.should_receive(:connect).and_return(connection)
        connection.should_receive(:send_data).with("put some_key 10000 2 index=1 job=Test tag=value\n")
        Collector::Config.logger.should_receive(:debug1).with("put some_key 10000 2 index=1 job=Test tag=value\n")
      end

      it "integrates with TSDB historians" do
        historian = Collector::Historian::Tsdb.new("host", 1234)
        handler = Collector::Handler.handler(historian, "Test", 1, 10000)

        handler.send_metric("some_key", 2, {:tag => "value"})
      end
    end

    context "CloudWatch" do
      before do
        AWS.should_receive(:config)

        cloud_watch = double('Cloud Watch')
        cloud_watch.should_receive(:put_metric_data).with({
            namespace: "CF/Collector",
            metric_data: [
                {
                    metric_name: "some_key",
                    value: "2",
                    timestamp: "2013-03-07T19:13:28Z",
                    dimensions: [
                        {name: "tag", value: "value"},
                        {name: "job", value: "Test"},
                        {name: "index", value: "1"},
                        {name: "deployment", value: "staging"},
                    ]
                }]
        })
        AWS::CloudWatch.should_receive(:new).and_return(cloud_watch)
      end

      it "integrates with CloudWatch historians" do
        historian = Collector::Historian::CloudWatch.new("access", "secret")
        handler = Collector::Handler.handler(historian, "Test", 1, 1362683608)

        handler.send_metric("some_key", 2, {:tag => "value"})
      end
    end
  end

  describe :send_latency_metric do
    it "should send the metric to the TSDB server" do
      connection = mock(:TsdbConnection)
      connection.should_receive(:send_data).
          with({key: "latency_key",
                timestamp: 10000,
                value: 5,
                tags: {index: 1, job: "Test", tag: "value"}})
      handler = Collector::Handler.handler(connection, "Test", 1, 10000)
      handler.send_latency_metric("latency_key",
                                  {"value" => 10, "samples" => 2},
                                  {:tag => "value"})
    end
  end
end