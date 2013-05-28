# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class RabbitmqProvisioner < ServiceGatewayHandler
      register Components::RABBITMQ_PROVISIONER

      def service_type
        "rabbitmq"
      end

    end
  end
end
