# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class Neo4jNode < ServiceHandler
      register Components::NEO4J_NODE

      def process
        process_healthy_instances_metric
      end

      def service_type
        "neo4j"
      end

      def component
        "node"
      end

    end
  end
end
