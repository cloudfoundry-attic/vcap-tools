# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class SerializationDataServer < ServiceHandler
      register Components::SERIALIZATION_DATA_SERVER

      def process
        if varz["nfs_free_space"]
          send_metric("services.nfs_free_space", varz["nfs_free_space"])
        end
      end

      def service_type
        "serialization_data_server"
      end

    end
  end
end
