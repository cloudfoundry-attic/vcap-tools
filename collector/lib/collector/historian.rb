require_relative "./historian/cloud_watch"
require_relative "./historian/tsdb"

module Collector
  class Historian
    def self.build
      historian = new

      historian.add_adapter(Historian::Tsdb.new(Config.tsdb_host, Config.tsdb_port)) if Config.tsdb
      historian.add_adapter(Historian::CloudWatch.new(Config.aws_access_key_id, Config.aws_secret_access_key)) if Config.aws_cloud_watch

      historian
    end

    attr_accessor :adapters

    def initialize
      self.adapters = []
    end

    def send_data(data)
      adapters.each do |adapter|
        begin
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