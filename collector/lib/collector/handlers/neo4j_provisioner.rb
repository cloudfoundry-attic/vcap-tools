# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class Neo4jProvisioner < ServiceHandler
      register Components::NEO4J_PROVISIONER

      def process
        process_plan_score_metric
        process_online_nodes
      end

      def service_type
        "neo4j"
      end

      def component
        "gateway"
      end

    end
  end
end
