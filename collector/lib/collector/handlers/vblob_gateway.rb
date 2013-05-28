# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class VblobProvisioner < ServiceGatewayHandler
      register Components::VBLOB_PROVISIONER

      def service_type
        "vblob"
      end

    end
  end
end
