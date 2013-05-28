# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class PostgresqlProvisioner < ServiceGatewayHandler
      register Components::PGSQL_PROVISIONER

      def service_type
        "postgresql"
      end

    end
  end
end
