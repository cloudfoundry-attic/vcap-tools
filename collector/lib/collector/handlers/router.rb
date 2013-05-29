# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class Router < Handler
      register Components::ROUTER_COMPONENT

      def process
        return unless varz["tags"]
        varz["tags"].each do |key, values|
          values.each do |value, metrics|
            tags = {key => value}
            # Add synthetic tag so we can isolate all the apps
            tags["component"] = "apps" if key == "framework"

            send_metric("router.requests", metrics["requests"], tags)
            send_latency_metric("router.latency.1m", metrics["latency"], tags)
            ["2xx", "3xx", "4xx", "5xx", "xxx"].each do |status_code|
              send_metric("router.responses", metrics["responses_#{status_code}"], tags.merge("status" => status_code))
            end
          end
        end
      end
    end
  end
end
