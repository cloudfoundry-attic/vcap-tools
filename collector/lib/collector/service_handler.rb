# Copyright (c) 2009-2012 VMware, Inc.
require_relative "handler"

module Collector
  class ServiceHandler < Handler
    def additional_tags
      {:service_type => service_type, :component => component}
    end

    # Process healthy instances percent for each service, default is 0 if
    # no instance provisioned.
    #
    def process_healthy_instances_metric
      healthy_instances = 0
      if varz["instances"]
        total_instances = varz["instances"].length
        healthy_instances = varz["instances"].values.count("ok")
        if (total_instances != 0)
          healthy_instances = format("%.2f",
                  healthy_instances.to_f / total_instances.to_f * 100)
        end
      end
      send_metric("services.healthy_instances", healthy_instances)
    end

    # Sum up all nodes' available_capacity value for each service, report
    # low_water & high_water value at the same time.
    #
    def process_plan_score_metric
      return unless varz.include?("plans")
      if varz["plans"]
        varz["plans"].each do |plan|
          tags = {
            :plan => plan["plan"],
          }
          allow_over_provisioning = plan.delete("allow_over_provisioning") ? 1 : 0
          send_metric("services.plans.allow_over_provisioning", allow_over_provisioning, tags)
          plan.each do |metric_name, value|
            send_metric("services.plans.#{metric_name}", value, tags)
          end
        end
      end
    end

    # Get online nodes varz for each service gateway, report the total
    # number of online nodes
    #
    def process_online_nodes
      return unless varz.include?("nodes")
      send_metric("services.online_nodes", varz["nodes"].length)
    end

    def service_type    # "mysql", "postgresql", "mongodb" ...
      "unknown"
    end

    def component       # "node", "gateway"
      "unknown"
    end
  end
end
