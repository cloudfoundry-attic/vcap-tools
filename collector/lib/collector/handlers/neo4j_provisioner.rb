# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class Neo4jProvisioner < ServiceGatewayHandler
      register Components::NEO4J_PROVISIONER

      def service_type
        "neo4j"
      end

    end
  end
end
