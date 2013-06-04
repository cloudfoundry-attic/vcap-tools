require 'spec_helper'

describe Collector::Handler::Router do

  class FakeHistorian
    attr_reader :sent_data

    def initialize
      @sent_data = []
    end

    def send_data(data)
      @sent_data << data
    end

    def has_sent_data?(key, value, tags={})
      @sent_data.any? do |data|
        data[:key] == key && data[:value] == value &&
          data[:tags] == data[:tags].merge(tags)
      end
    end
  end

  let(:historian) { FakeHistorian.new }
  let(:timestamp) { 123456789 }
  let(:handler) { Collector::Handler::Router.new(historian, "job") }
  let(:context) { Collector::HandlerContext.new(1, timestamp, varz) }

  describe "process" do
    let(:varz) do
      {
        "latency" => {
          "50" => 0.0250225,
          "75" => 0.03684,
          "90" => 0.09650980000000002,
          "95" => 0.3351683999999978,
          "99" => 1.314998740000001,
          "samples" => 1,
          "value" => 5.0e-07
        },
        "rate" => [
          0.22460493344950977,
          0.49548432897218125,
          0.9014480037952
        ],
          "requests" => 68213,
          "requests_per_sec" => 0.22460493344950977,
          "responses_2xx" => 65021,
          "responses_3xx" => 971,
          "responses_4xx" => 2182,
          "responses_5xx" => 1,
          "responses_xxx" => 38,
          "start" => "2013-05-28 22:01:19 +0000",
          "tags" => {
            "component" => {
            }
          },
          "urls" => 123456789
      }
    end

    describe "normal components" do
      let(:component) do
        {
          "latency" => {
            "50" => 0.025036,
            "75" => 0.034314,
            "90" => 0.0791451,
            "95" => 0.1607238499999999,
            "99" => 1.1623077700000013,
            "samples" => 1,
            "value" => 5
          },
          "rate" => [
            0.22490272672626982,
            0.4771015543892108,
            0.8284101734116986
          ],
            "requests" => 3200,
            "responses_2xx" => 100,
            "responses_3xx" => 200,
            "responses_4xx" => 400,
            "responses_5xx" => 800,
            "responses_xxx" => 1600
        }
      end

      before do
        varz['tags']['component']['component-1'] = component
      end

      it "sends the metrics" do
        tags = {"component" => "component-1"}

        handler.process(context)
        historian.should have_sent_data("router.requests", 3200, tags)
        historian.should have_sent_data("router.latency.1m", 5, tags)

        historian.should have_sent_data("router.responses", 100, tags.merge("status" => "2xx"))
        historian.should have_sent_data("router.responses", 200, tags.merge("status" => "3xx"))
        historian.should have_sent_data("router.responses", 400, tags.merge("status" => "4xx"))
        historian.should have_sent_data("router.responses", 800, tags.merge("status" => "5xx"))
        historian.should have_sent_data("router.responses", 1600, tags.merge("status" => "xxx"))

        historian.should have_sent_data("router.total_requests", 68213)
        historian.should have_sent_data("router.total_routes", 123456789)
      end
    end


    describe "dea-related components (i.e., apps)" do
      let(:component) do
        {
          "latency" => {
            "50" => 0.025036,
            "75" => 0.034314,
            "90" => 0.0791451,
            "95" => 0.1607238499999999,
            "99" => 1.1623077700000013,
            "samples" => 1,
            "value" => 5
          },
          "rate" => [
            0.22490272672626982,
            0.4771015543892108,
            0.8284101734116986
          ],
            "requests" => 2400,
            "responses_2xx" => 200,
            "responses_3xx" => 300,
            "responses_4xx" => 400,
            "responses_5xx" => 500,
            "responses_xxx" => 1000
        }
      end

      it "sends metrics tagged with component:dea and dea_index:x" do
        varz['tags']['component']['dea-2'] = component

        tags = {:component => "app", :dea_index => "2"}

        handler.process(context)
        historian.should have_sent_data("router.requests", 2400, tags)
        historian.should have_sent_data("router.latency.1m", 5, tags)
      end
    end
  end
end
