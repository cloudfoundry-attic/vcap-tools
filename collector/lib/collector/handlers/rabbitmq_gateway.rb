# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class RabbitmqProvisioner < ServiceHandler
      register Components::RABBITMQ_PROVISIONER

      def process
        process_plan_score_metric
        process_online_nodes
      end

      def service_type
        "rabbitmq"
      end

      def component
        "gateway"
      end

    end
  end
end
