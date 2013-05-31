# Copyright (c) 2009-2012 VMware, Inc.

require File.expand_path("../../spec_helper", File.dirname(__FILE__))

describe Collector::ServiceGatewayHandler do
  it "has the right component type" do
    handler = Collector::ServiceGatewayHandler.new(nil, nil)
    handler.component.should == "gateway"
  end

  describe "#process" do
    it "should call the other process methods" do
      context = Object.new
      handler = Collector::ServiceGatewayHandler.new(nil, nil)
      handler.should_receive(:process_plan_score_metric).with(context)
      handler.should_receive(:process_online_nodes).with(context)
      handler.should_receive(:process_response_codes).with(context)
      handler.process(context)
    end
  end

  describe "#process_plan_score_metric" do
    let(:history_data) { Hash.new { |h, k| h.store(k, []) } }
    let(:historian) do
      double("Historian").tap do |h|
        h.stub(:send_data) do |data|
          name = data.fetch(:key)
          history_data[name] << data
        end
      end
    end

    let(:varz) do
      {
        "plans" => [
          {
            "plan" => "free",
            "low_water" => 100,
            "high_water" => 1400,
            "score" => 150,
            "max_capacity" => 500,
            "available_capacity" => 450,
            "used_capacity" => 50
          }
        ]
      }
    end

    let(:context) { Collector::HandlerContext.new(1, 10000, varz) }

    def self.test_report_metric(metric_name, key, value)
      it "should report #{key} to TSDB server" do
        handler = Collector::ServiceGatewayHandler.new(historian, "Test")
        handler.process_plan_score_metric(context)
        history_data.fetch(metric_name).should have(1).item
        history_data.fetch(metric_name).fetch(0).should include(
          key: metric_name,
          value: value,
        )
      end
    end

    test_report_metric("services.plans.low_water", "low_water", 100)
    test_report_metric("services.plans.high_water", "high_water", 1400)
    test_report_metric("services.plans.score", "score", 150)
    test_report_metric("services.plans.allow_over_provisioning", "allow_over_provisioning", 0)
    test_report_metric("services.plans.used_capacity", "used_capacity", 50)
    test_report_metric("services.plans.max_capacity", "max_capacity", 500)
    test_report_metric("services.plans.available_capacity", "available_capacity", 450)
  end

  describe "response code metrics" do
    class FakeHistorian
      attr_reader :sent_data

      def initialize
        @sent_data = []
      end

      def send_data(data)
        @sent_data << data
      end

      def sent_data?(key, value, tags)
        @sent_data.any? do |data|
          data[:key] == key && data[:value] == value &&
            data[:tags] == data[:tags].merge(tags)
        end
      end
    end

    let(:varz) do
      {
        "responses_metrics" => {
          "responses_2xx" => 2,
          "responses_3xx" => 3,
          "responses_4xx" => 4,
          "responses_5xx" => 5,
        }
      }
    end

    let(:timestamp) { 1000 }
    let(:historian) { FakeHistorian.new }
    let(:context) { Collector::HandlerContext.new(1, timestamp, varz) }
    let(:handler) { Collector::ServiceGatewayHandler.new(historian, "job") }

    it "reports response code metrics to the historian" do
      handler.process_response_codes(context)
      historian.sent_data?("services.http_status.2xx", 2,
        {service_type: "unknown", component: "gateway"}).should == true
      historian.sent_data?("services.http_status.3xx", 3,
        {service_type: "unknown", component: "gateway"}).should == true
      historian.sent_data?("services.http_status.4xx", 4,
        {service_type: "unknown", component: "gateway"}).should == true
      historian.sent_data?("services.http_status.5xx", 5,
        {service_type: "unknown", component: "gateway"}).should == true
    end
  end

  describe :process_online_nodes do
    it "should report online nodes number to TSDB server" do
      historian = mock("Historian")
      historian.should_receive(:send_data).
        with({
        key: "services.online_nodes",
        timestamp: 10_000,
        value: 2,
        tags: hash_including({
          component: "gateway",
          index: 1,
          job: "Test",
          service_type: 'unknown'
        })
      })
      varz = {
        "nodes" => {
          "node_0" => {
            "available_capacity" => 50,
            "plan" => "free"
          },
          "node_1" => {
            "available_capacity" => 50,
            "plan" => "free"
          }
        }
      }
      context = Collector::HandlerContext.new(1, 10000, varz)
      handler = Collector::ServiceGatewayHandler.new(historian, "Test")
      handler.process_online_nodes(context)
    end
  end

end
