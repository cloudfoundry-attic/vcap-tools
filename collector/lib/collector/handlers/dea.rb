# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class Dea < Handler
      register Components::DEA_COMPONENT

      def additional_tags(context)
        { stack: context.varz['stacks'] }
      end

      def process(context)
        send_metric("can_stage", context.varz["can_stage"], context)
      end
    end
  end
end
