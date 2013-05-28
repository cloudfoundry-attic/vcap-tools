# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class MysqlNode < ServiceNodeHandler
      register Components::MYSQL_NODE

      def service_type
        "mysql"
      end
    end
  end
end
