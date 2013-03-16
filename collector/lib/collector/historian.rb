require_relative "./historian/cloud_watch"
require_relative "./historian/tsdb"

module Collector
  class Historian
    def self.build
      historian = new

      if Config.tsdb
        historian.add_adapter(Historian::Tsdb.new(Config.tsdb_host, Config.tsdb_port))
        ::Collector::Config.logger.info("Adding historian adapter for TSDB #{Config.tsdb_host}")
      end

      if Config.aws_cloud_watch
        historian.add_adapter(Historian::CloudWatch.new(Config.aws_access_key_id, Config.aws_secret_access_key))
        ::Collector::Config.logger.info("Adding historian adapter for CloudWatch with AWS access key #{Config.aws_access_key_id}")
      end

      historian
    end

    attr_accessor :adapters

    def initialize
      self.adapters = []
    end

    def send_data(data)
      adapters.each do |adapter|
        begin
          ::Collector::Config.logger.debug("Sending data to #{adapter.class.name}: #{data}")
          adapter.send_data(data)
        rescue => e
          ::Collector::Config.logger.warn("Error sending data to #{adapter.class.name}: #{e.inspect} - #{e.message}")
        end
      end
    end

    def add_adapter(adapter)
      self.adapters << adapter
    end
  end
end