# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class PostgresqlNode < ServiceHandler
      register Components::PGSQL_NODE

      def process
        process_healthy_instances_metric
      end

      def service_type
        "postgresql"
      end

      def component
        "node"
      end

    end
  end
end
