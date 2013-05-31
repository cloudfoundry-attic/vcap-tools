# Copyright (c) 2009-2012 VMware, Inc.
module Collector
  class Handler
    class HealthManager < Handler
      register Components::HEALTH_MANAGER_COMPONENT
      METRICS = {
              "total" => {
                      "apps" => "apps",
                      "started_apps" => "started_apps",
                      "instances" => "instances",
                      "started_instances" => "started_instances",
                      "memory" => "memory",
                      "started_memory" => "started_memory"
              },
              "running" => {
                      "apps" => "running_apps",
                      "crashes" => "crashes",
                      "running_instances" => "running_instances",
                      "missing_instances" => "missing_instances",
                      "flapping_instances" => "flapping_instances"
              }
      }


      def process(context)
        varz = context.varz
        METRICS.each do |type, metric_map|
          if type_varz = varz[type]
            metric_map.each do |varz_name, metric_name|
              if type_varz[varz_name]
                send_metric("#{type}.#{metric_name}", type_varz[varz_name], context)
              end
            end
          end
        end

        send_metric("total_users", varz["total_users"], context) if varz["total_users"]
      end
    end
  end
end
