# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  class Handler
    class BackupManager < ServiceHandler
      register BACKUP_MANAGER

      def process(varz)
        total_size = varz["disk_total_size"] || 0
        used_size = varz["disk_used_size"] || 0
        used_percent = 0
        if (total_size != 0)
          used_percent = used_size.to_f / total_size.to_f * 100
        end
        send_metric("services.nfs_used_space", used_percent)
      end

      def service_type
        "backup_manager"
      end

    end
  end
end
