# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class Dea < Handler
      register Components::DEA_COMPONENT

      def additional_tags
        { stack: varz['stacks'] }
      end
    end
  end
end
