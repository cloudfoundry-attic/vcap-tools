# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class RabbitmqNode < ServiceNodeHandler
      register Components::RABBITMQ_NODE

      def service_type
        "rabbitmq"
      end
    end
  end
end
