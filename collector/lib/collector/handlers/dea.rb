# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class Dea < Handler
      register Components::DEA_COMPONENT

      def additional_tags
        { stack: varz['stacks'] }
      end

      def process
        send_metric("can_stage", varz["can_stage"])
      end
    end
  end
end
