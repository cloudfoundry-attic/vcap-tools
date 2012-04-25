# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class Neo4jProvisioner < ServiceHandler
      register NEO4J_PROVISIONER

      def process(varz)
        process_plan_score_metric(varz)
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
