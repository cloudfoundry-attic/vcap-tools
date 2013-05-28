# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class PostgresqlNode < ServiceNodeHandler
      register Components::PGSQL_NODE

      def service_type
        "postgresql"
      end
    end
  end
end
