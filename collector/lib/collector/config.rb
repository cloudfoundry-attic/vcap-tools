# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  # Singleton config used throughout
  class Config
    class << self

      OPTIONS = [
        :index,
        :logger,
        :tsdb_host,
        :tsdb_port,
        :aws_access_key_id,
        :aws_secret_access_key,
        :datadog_api_key,
        :datadog_application_key,
        :nats_uri,
        :discover_interval,
        :varz_interval,
        :healthz_interval,
        :prune_interval,
        :nats_ping_interval,
        :local_metrics_interval,
        :deployment_name
      ]

      OPTIONS.each { |option| attr_accessor option }

      def tsdb
        tsdb_host && tsdb_port
      end

      def aws_cloud_watch
        aws_access_key_id && aws_secret_access_key
      end

      def datadog
        datadog_api_key && datadog_application_key
      end

      # Configures the various attributes
      #
      # @param [Hash] config the config Hash
      def configure(config)
        @index = config["index"].to_i
        VCAP::Logging.setup_from_config(config["logging"])
        @logger = VCAP::Logging.logger("collector")

        @deployment_name = config["deployment_name"] || "untitled_dev"

        tsdb_config = config["tsdb"] || {}
        @tsdb_host = tsdb_config["host"]
        @tsdb_port = tsdb_config["port"]

        aws_config = config["aws_cloud_watch"] || {}
        @aws_access_key_id = aws_config["access_key_id"]
        @aws_secret_access_key = aws_config["secret_access_key"]

        datadog_config = config["datadog"] || {}
        @datadog_api_key = datadog_config["api_key"]
        @datadog_application_key = datadog_config["application_key"]

        @nats_uri = config["mbus"]

        intervals = config["intervals"]

        @discover_interval = intervals["discover"] || 60
        @varz_interval = intervals["varz"] || 10
        @healthz_interval = intervals["healthz"] || 5
        @prune_interval = intervals["prune"] || 300
        @nats_ping_interval = intervals["nats_ping"] || 10
        @local_metrics_interval = intervals["local_metrics"] || 10
      end
    end
  end
end
