# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class RedisNode < ServiceHandler
      register Components::REDIS_NODE

      def process
        process_healthy_instances_metric
      end

      def service_type
        "redis"
      end

      def component
        "node"
      end

    end
  end
end
