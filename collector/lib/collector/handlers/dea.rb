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
        send_metric("reservable_stagers", context.varz["reservable_stagers"], context)
        send_metric("available_memory_ratio", context.varz["available_memory_ratio"], context)
        send_metric("available_disk_ratio", context.varz["available_disk_ratio"], context)
      end
    end
  end
end
