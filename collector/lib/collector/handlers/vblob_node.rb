# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class VblobNode < ServiceHandler
      register Components::VBLOB_NODE

      def process
        process_healthy_instances_metric
      end

      def service_type
        "vblob"
      end

      def component
        "node"
      end

    end
  end
end
