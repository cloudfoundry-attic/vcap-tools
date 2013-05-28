# Copyright (c) 2009-2012 VMware, Inc.
require_relative "service_handler"

module Collector
  class ServiceNodeHandler < ServiceHandler
    def process
      process_healthy_instances_metric
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

    def component
      "node"
    end
  end
end
