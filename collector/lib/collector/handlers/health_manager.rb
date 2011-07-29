module Collector
  class Handler
    class HealthManager < Handler

      register HEALTH_MANAGER_COMPONENT

      METRICS = {
        "total" => ["total_apps", "total_instances", "total_memory"],
        "running" => ["running_apps", "crashes", "running_instances", "missing_instances", "flapping_instances"]
      }

      def process(varz)

        METRICS.each do |type, metric_names|
          if type_varz = varz[type]
            if framework_varz = type_varz["frameworks"]
              framework_varz.each do |framework, metrics|
                metric_names.each do |metric_name|
                  send_metric("frameworks.#{metric_name}", metrics[metric_name], :framework => framework)
                end
              end
            end

            if runtime_varz = type_varz["runtimes"]
              runtime_varz.each do |runtime, metrics|
                metric_names.each do |metric_name|
                  send_metric("runtimes.#{metric_name}", metrics[metric_name], :runtime => runtime)
                end
              end
            end
          end
        end

        send_latency_metric("nats.latency.1m", varz["nats_latency"])
      end

    end
  end
end