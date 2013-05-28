# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class VblobNode < ServiceNodeHandler
      register Components::VBLOB_NODE

      def service_type
        "vblob"
      end
    end
  end
end
