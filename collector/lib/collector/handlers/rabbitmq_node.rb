# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class RabbitmqNode < ServiceHandler
      register Components::RABBITMQ_NODE

      def process
        process_healthy_instances_metric
      end

      def service_type
        "rabbitmq"
      end

      def component
        "node"
      end

    end
  end
end
