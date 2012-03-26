# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class ServiceHandler < Handler
    def initialize(tsdb_connection, job, index, now)
      super(tsdb_connection, job, index, now)
    end

    def send_metric(name, value, tags = {})
      default_tags = {:service_type => "#{service_type}",
                      :component => "#{component}",
                      :index => @index}
      tags = tags.merge(default_tags).
                  collect { |tag| tag.join("=") }.sort.join(" ")
      command = "put #{name} #{@now} #{value} #{tags}\n"
      @logger.debug1(command)
      @tsdb_connection.send_data(command)
    end

    # Process healthy instances percent for each service, default is 0 if
    # no instance provisioned.
    #
    def process_healthy_instances_metric(varz)
      healthy_instances = 0
      if varz["instances"]
        total_instances = varz["instances"].length
        varz["instances"].each do |key, value|
          if value == "ok"
            healthy_instances += 1
          end
        end
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
    def process_plan_score_metric(varz)
       config = varz["config"] || {}
       planmgr = config["plan_management"] || {}
       plans = planmgr["plans"] || {}
       plans.each do |plan_name, plan_info|
         high_water = plan_info["high_water"] || 0
         low_water = plan_info["low_water"] || 0
         send_metric("services.plans.high_water", high_water,
                      {:plan => "#{plan_name}"})
         send_metric("services.plans.low_water", low_water,
                      {:plan => "#{plan_name}"})
       end

       total_score = 0
       plan = ""
       nodes = varz["nodes"] || {}
       nodes.each do |node_name, node_info|
         score = node_info["available_capacity"] || 0
         # NOTE: here we suppose all nodes' plan are the same
         plan = node_info["plan"] || "unknown"
         total_score += score
       end
       if total_score != 0
         send_metric("services.plans.score", total_score, {:plan => "#{plan}"})
       end
    end

    def service_type    # "mysql", "postgresql", "mongodb" ...
      "unknown"
    end

    def component       # "node", "gateway"
      "unknown"
    end
  end
end
