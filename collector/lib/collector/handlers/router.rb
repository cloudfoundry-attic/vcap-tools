module Collector
  class Handler
    class Router < Handler

      register ROUTER_COMPONENT

      def process(varz)
        if varz["tags"]
          varz["tags"].each do |key, values|
            values.each do |value, metrics|
              send_metric("router.requests", metrics["requests"], key => value)
              send_latency_metric("router.latency.1m", metrics["latency"], key => value)
              ["2xx", "3xx", "4xx", "5xx", "xxx"].each do |status_code|
                send_metric("router.responses", metrics["responses_#{status_code}"],
                            key => value, "status" => status_code)
              end
            end
          end
        end
      end

    end
  end
end