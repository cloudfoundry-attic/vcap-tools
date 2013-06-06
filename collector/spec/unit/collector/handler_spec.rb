require "spec_helper"

describe Collector::Handler do
  after do
    Collector::Handler.handler_map.clear
    Collector::Handler.instance_map.clear
  end

  describe "register" do
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

    it "should return the registered varz handler plugin" do
      test_handler = Class.new(Collector::Handler) { register "Test" }
      Collector::Handler.handler(nil, "Test").should be_kind_of(test_handler)
    end

    it "should return cached handler after the first call" do
      test_handler_class = Class.new(Collector::Handler) { register "Test" }
      handler1 = Collector::Handler.handler(nil, "Test")
      handler2 = Collector::Handler.handler(nil, "Test")
      expect(handler1).to equal handler2
    end

    it "should return the default handler when none registered" do
      Collector::Handler.handler(nil, "Test").should be_kind_of(Collector::Handler)
    end
  end

  describe "do_process" do

    it "calls #process defined by the subclass" do
      context = Collector::HandlerContext.new(nil, nil, {})
      handler = Collector::Handler.new(nil, nil)
      handler.should_receive(:process).with(context)
      handler.do_process(context)
    end

    it "sends out 'mem_used_bytes' if specified" do
      context = Collector::HandlerContext.new(nil, nil, {"mem_used_bytes" => 2048})
      handler = Collector::Handler.new(nil, nil)
      handler.should_receive(:send_metric).with("mem_used_bytes", 2048, context)
      handler.do_process(context)
    end

    it "sends out 'mem_free_bytes' if specified" do
      context = Collector::HandlerContext.new(nil, nil, {"mem_free_bytes" => 2048})
      handler = Collector::Handler.new(nil, nil)
      handler.should_receive(:send_metric).with("mem_free_bytes", 2048, context)

      handler.do_process(context)
    end

    it "sends out 'cpu_load_avg' if specified" do
      context = Collector::HandlerContext.new(nil, nil, {"cpu_load_avg" => 2.0})
      handler = Collector::Handler.new(nil, nil)
      handler.should_receive(:send_metric).with("cpu_load_avg", 2.0, context)

      handler.do_process(context)
    end

    it "sends out log counts if specified" do
      context = Collector::HandlerContext.new(nil, nil, {"log_counts" => { "error" => 4, "warn" => 3}})
      handler = Collector::Handler.new(nil, nil)
      handler.should_receive(:send_metric).with("log_count", 4, context, {"level" => "error"})
      handler.should_receive(:send_metric).with("log_count", 3, context, {"level" => "warn"})

      handler.do_process(context)
    end
  end

  describe "sent tags" do
    let(:historian) { double }
    let(:handler) { Collector::Handler.new(historian, "DEA") }
    let(:context) { Collector::HandlerContext.new(0, nil, {"cpu_load_avg" => "42"}) }

    it "adds extra tags when specified" do
      handler.stub(:additional_tags => {foo: "bar"})
      historian.should_receive(:send_data).with(hash_including({
        tags: hash_including({
          foo: "bar"
        })
      }))
      handler.do_process(context)
    end

    it "sends the common tags" do
      historian.should_receive(:send_data).with(hash_including({
        tags: hash_including({
          job: "DEA",
          index: 0,
          role: "core"
        })
      }))
      handler.do_process(context)
    end
  end

  describe "send_metric" do
    it "should send the metric to the Historian" do
      historian = mock('Historian')
      historian.should_receive(:send_data).with(
                key: "some_key",
                timestamp: 10000,
                value: 2,
                tags: {index: 1, job: "Test", name: "Test/1", deployment: "untitled_dev", foo: "bar"}
      )

      context = Collector::HandlerContext.new(1, 10000, {})
      handler = Collector::Handler.handler(historian, "Test")
      handler.send_metric("some_key", 2, context, {foo: "bar"})
    end

    it "should not allow additional_tags to override base tags" do
      historian = mock('Historian')
      historian.should_receive(:send_data).with(
          key: "some_key",
          timestamp: 10000,
          value: 2,
          tags: {index: 1, job: "DEA", name: "DEA/1", deployment: "untitled_dev", role: "core"}
      )

      context = Collector::HandlerContext.new(1, 10000, {})
      handler = Collector::Handler.handler(historian, "DEA")
      handler.stub(:additional_tags => {
        job: "foo",
        index: "foo",
        name: "foo",
        deployment: "foo",
        role: "foo"
      })
      handler.send_metric("some_key", 2, context)
    end
  end

  describe "send_latency_metric" do
    it "should send the metric to the historian" do
      historian = mock("historian")
      historian.should_receive(:send_data).
          with({key: "latency_key",
                timestamp: 10000,
                value: 5,
                tags: hash_including({index: 1, job: "Test", foo: "bar"})})
      context = Collector::HandlerContext.new(1, 10000, {})
      handler = Collector::Handler.handler(historian, "Test")
      handler.send_latency_metric("latency_key", {"value" => 10, "samples" => 2}, context, {foo: "bar"})
    end
  end
end