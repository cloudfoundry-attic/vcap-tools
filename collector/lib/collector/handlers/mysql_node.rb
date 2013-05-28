# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class MysqlNode < ServiceHandler
      register Components::MYSQL_NODE

      def process
        process_healthy_instances_metric
      end

      def service_type
        "mysql"
      end

      def component
        "node"
      end

    end
  end
end
