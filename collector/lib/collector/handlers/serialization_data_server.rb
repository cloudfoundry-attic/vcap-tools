# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class SerializationDataServer < Handler
      register SERIALIZATION_DATA_SERVER

      def process(varz)
        if varz["nfs_free_space"]
          send_metric("nfs_free_space", varz["nfs_free_space"],
                      {:service_type => service_type,
                       :index => @index})
        end
      end

      def service_type
        "serialization_data_server"
      end

    end
  end
end
