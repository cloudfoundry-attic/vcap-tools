require "spec_helper"

describe Collector::Handler do
  describe "register" do
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

  describe "handler" do
    after { Collector::Handler.handler_map.clear }

    it "should return the registered varz handler plugin" do
      test_handler = Class.new(Collector::Handler) { register "Test" }
      Collector::Handler.handler(nil, "Test", nil, nil, {}).
          should be_kind_of(test_handler)
    end

    it "should return the default handler when none registered" do
      Collector::Handler.handler(nil, "Test", nil, nil, {}).should be_kind_of(Collector::Handler)
    end
  end

  describe "#do_process" do
    it "calls #process defined by the subclass" do
      handler = Collector::Handler.new(nil, nil, nil, nil, {})
      handler.should_receive(:process).with()
      handler.do_process()
    end

    it "sends out 'mem' if specified" do
      handler = Collector::Handler.new(nil, nil, nil, nil, {"mem" => 2048})
      handler.should_receive(:send_metric).with("mem", 2)
      handler.do_process
    end

    it "sends out 'mem_used_bytes' if specified" do
      handler = Collector::Handler.new(nil, nil, nil, nil, {"mem_used_bytes" => 2048})
      handler.should_receive(:send_metric).with("mem_used_bytes", 2048)

      handler.do_process
    end
    it "sends out 'mem_free_bytes' if specified" do
      handler = Collector::Handler.new(nil, nil, nil, nil, {"mem_free_bytes" => 2048})
      handler.should_receive(:send_metric).with("mem_free_bytes", 2048)

      handler.do_process
    end
    it "sends out 'cpu_load_avg' if specified" do
      handler = Collector::Handler.new(nil, nil, nil, nil, {"cpu_load_avg" => 2.0})
      handler.should_receive(:send_metric).with("cpu_load_avg", 2.0)

      handler.do_process
    end
  end

  describe "sent tags" do
    let(:historian) { double }
    let(:handler) { Collector::Handler.new(historian, "DEA", 0, nil, {"cpu_load_avg" => "42"}) }

    it "adds extra tags when specified" do
      handler.stub(:additional_tags => {foo: "bar"})
      historian.should_receive(:send_data).with(hash_including({
        tags: hash_including({
          foo: "bar"
        })
      }))
      handler.do_process
    end

    it "sends the common tags" do
      historian.should_receive(:send_data).with(hash_including({
        tags: hash_including({
          job: "DEA",
          index: 0,
          role: "core"
        })
      }))
      handler.do_process
    end
  end

  describe "send_metric" do
    it "should send the metric to the Historian" do
      historian = mock('Historian')
      historian.should_receive(:send_data).
          with({key: "some_key",
                timestamp: 10000,
                value: 2,
                tags: {index: 1, job: "Test", name: "Test/1", deployment: "untitled_dev"}})

      handler = Collector::Handler.handler(historian, "Test", 1, 10000, {})
      handler.send_metric("some_key", 2)
    end

    it "should not allow additional_tags to override base tags" do
      historian = mock('Historian')
      historian.should_receive(:send_data).
        with({
          key: "some_key",
          timestamp: 10000,
          value: 2,
          tags: {index: 1, job: "DEA", name: "DEA/1", deployment: "untitled_dev", role: "core"}
        })

      handler = Collector::Handler.handler(historian, "DEA", 1, 10000, {})
      handler.stub(:additional_tags => {
        job: "foo",
        index: "foo",
        name: "foo",
        deployment: "foo",
        role: "foo"
      })
      handler.send_metric("some_key", 2)
    end
  end

  describe "send_latency_metric" do
    it "should send the metric to the TSDB server" do
      connection = mock(:TsdbConnection)
      connection.should_receive(:send_data).
          with({key: "latency_key",
                timestamp: 10000,
                value: 5,
                tags: hash_including({index: 1, job: "Test"})})
      handler = Collector::Handler.handler(connection, "Test", 1, 10000, {})
      handler.send_latency_metric("latency_key", {"value" => 10, "samples" => 2})
    end
  end
end