# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class MysqlProvisioner < ServiceGatewayHandler
      register Components::MYSQL_PROVISIONER

      def service_type
        "mysql"
      end

    end
  end
end
