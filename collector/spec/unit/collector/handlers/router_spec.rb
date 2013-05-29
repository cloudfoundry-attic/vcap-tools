require 'spec_helper'

describe Collector::Handler::Router do
  describe "#process" do
    it "processes" do
      varz = JSON.parse <<-JSON
{
  "latency": {
    "50": 0.0250225,
    "75": 0.03684,
    "90": 0.09650980000000002,
    "95": 0.3351683999999978,
    "99": 1.314998740000001,
    "samples": 1,
    "value": 5.0e-07
  },
  "rate": [
    0.22460493344950977,
    0.49548432897218125,
    0.9014480037952
  ],
  "requests": 68213,
  "requests_per_sec": 0.22460493344950977,
  "responses_2xx": 65021,
  "responses_3xx": 971,
  "responses_4xx": 2182,
  "responses_5xx": 1,
  "responses_xxx": 38,
  "start": "2013-05-28 22:01:19 +0000",
  "tags": {
    "component": {
      "component-1": {
        "latency": {
          "50": 0.025036,
          "75": 0.034314,
          "90": 0.0791451,
          "95": 0.1607238499999999,
          "99": 1.1623077700000013,
          "samples": 1,
          "value": 5
        },
        "rate": [
          0.22490272672626982,
          0.4771015543892108,
          0.8284101734116986
        ],
        "requests": 1234,
        "responses_2xx": 200,
        "responses_3xx": 300,
        "responses_4xx": 400,
        "responses_5xx": 500,
        "responses_xxx": 1000
      }
    },
    "framework": {
    },
    "runtime": {
    }
  }
}
      JSON

      tags = {"component" => "component-1"}
      handler = Collector::Handler::Router.new(nil, nil, nil, nil, varz)
      handler.should_receive(:send_metric).with("router.requests", 1234, tags)
      component_latency = varz["tags"]["component"]["component-1"]["latency"]
      handler.should_receive(:send_latency_metric).with("router.latency.1m", component_latency, tags)
      handler.should_receive(:send_metric).with("router.responses", 200, tags.merge("status" => "2xx"))
      handler.should_receive(:send_metric).with("router.responses", 300, tags.merge("status" => "3xx"))
      handler.should_receive(:send_metric).with("router.responses", 400, tags.merge("status" => "4xx"))
      handler.should_receive(:send_metric).with("router.responses", 500, tags.merge("status" => "5xx"))
      handler.should_receive(:send_metric).with("router.responses", 1000, tags.merge("status" => "xxx"))

      handler.process
    end
  end
end