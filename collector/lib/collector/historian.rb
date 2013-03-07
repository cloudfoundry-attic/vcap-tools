require_relative "./historian/cloud_watch"
require_relative "./historian/tsdb"

module Collector
  module Historian
      def self.build
        if Config.tsdb
          Historian::Tsdb.new(Config.tsdb_host, Config.tsdb_port)
        elsif Config.aws_cloud_watch
          Historian::CloudWatch.new(Config.aws_access_key_id, Config.aws_secret_access_key)
        end
      end
    end
end