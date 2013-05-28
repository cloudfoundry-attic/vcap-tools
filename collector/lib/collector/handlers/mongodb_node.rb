# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class MongodbNode < ServiceNodeHandler
      register Components::MONGODB_NODE

      def service_type
        "mongodb"
      end

    end
  end
end
