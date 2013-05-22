require "spec_helper"

describe Collector::Handler do
  describe :register do
    after { Collector::Handler.handler_map.clear }

    it "should register varz handler plugins" do
      test_handler = Class.new(Collector::Handler) { register "Test" }
      Collector::Handler.handler_map.should include("Test" => test_handler)
    end

    it "should fail to register multiple handlers for a single job" do
      Class.new(Collector::Handler) { register "Test" }

      expect {
        Class.new(Collector::Handler) { register "Test" }
      }.to raise_exception "Job: Test already registered"
    end
  end

  describe :handler do
    after { Collector::Handler.handler_map.clear }

    it "should return the registered varz handler plugin" do
      test_handler = Class.new(Collector::Handler) { register "Test" }
      Collector::Handler.handler(nil, "Test", nil, nil).
          should be_kind_of(test_handler)
    end

    it "should return the default handler when none registered" do
      Collector::Handler.handler(nil, "Test", nil, nil).should be_kind_of(Collector::Handler)
    end
  end

  describe "#is_healthy?" do
    it "is true for 'ok'" do
      expect(Collector::Handler.new(nil, nil, nil, nil).is_healthy?("ok")).to eq(true)
    end

    it "is false for non-ok" do
      expect(Collector::Handler.new(nil, nil, nil, nil).is_healthy?("the collector is my favorite")).to eq(false)
    end
  end

  describe "#do_process" do
    let(:handler) { Collector::Handler.new(nil, nil, nil, nil) }

    it "calls #process defined by the subclass" do
      varz = {one: 1}
      handler.should_receive(:process).with(varz)

      handler.do_process(varz, {})
    end

    it "sends out 'mem' if specified" do
      varz = {"mem" => 2048}
      handler.should_receive(:send_metric).with("mem", 2, {})

      handler.do_process(varz, {})
    end

    it "sends out 'mem_used_bytes' if specified" do
      varz = {"mem_used_bytes" => 2048}
      handler.should_receive(:send_metric).with("mem_used_bytes", 2048, {})

      handler.do_process(varz, {})
    end
    it "sends out 'mem_free_bytes' if specified" do
      varz = {"mem_free_bytes" => 2048}
      handler.should_receive(:send_metric).with("mem_free_bytes", 2048, {})

      handler.do_process(varz, {})
    end
    it "sends out 'cpu_load_avg' if specified" do
      varz = {"cpu_load_avg" => 2.0}
      handler.should_receive(:send_metric).with("cpu_load_avg", 2.0, {})

      handler.do_process(varz, {})
    end
  end

  describe "send_metric" do
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
                        {name: "name", value: "Test/1"},
                        {name: "deployment", value: "dev113cw"},
                    ]
                }]
        })
        AWS::CloudWatch.should_receive(:new).and_return(cloud_watch)
      end

      it "integrates with CloudWatch historians" do
        historian = Collector::Historian::CloudWatch.new("access", "secret")
        handler = Collector::Handler.handler(historian, "Test", 1, 1362683608)
        ::Collector::Config.stub(:deployment_name).and_return("dev113cw")

        handler.send_metric("some_key", 2, {:tag => "value"})
      end
    end
  end

  describe "send_latency_metric" do
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