# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class RedisNode < ServiceNodeHandler
      register Components::REDIS_NODE

      def service_type
        "redis"
      end
    end
  end
end
