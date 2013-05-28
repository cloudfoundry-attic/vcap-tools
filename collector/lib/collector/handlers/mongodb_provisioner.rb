# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class MongodbProvisioner < ServiceGatewayHandler
      register Components::MONGODB_PROVISIONER

      def service_type
        "mongodb"
      end

    end
  end
end
