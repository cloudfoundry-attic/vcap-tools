# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class RedisProvisioner < ServiceGatewayHandler
      register Components::REDIS_PROVISIONER

      def service_type
        "redis"
      end

    end
  end
end
