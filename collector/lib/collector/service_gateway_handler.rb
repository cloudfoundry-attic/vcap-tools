# Copyright (c) 2009-2012 VMware, Inc.
require_relative "service_handler"

module Collector
  class ServiceGatewayHandler < ServiceHandler
    def process
      process_plan_score_metric
      process_online_nodes
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

    def component
      "gateway"
    end
  end
end
