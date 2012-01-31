module Collector
  # Singleton config used throughout
  class Config
    class << self

      OPTIONS = [
        :index,
        :logger,
        :tsdb_host,
        :tsdb_port,
        :nats_uri,
        :discover_interval,
        :varz_interval,
        :healthz_interval,
        :prune_interval,
        :nats_ping_interval,
        :local_metrics_interval
      ]

      OPTIONS.each { |option| attr_accessor option }

      # Configures the various attributes
      #
      # @param [Hash] config the config Hash
      def configure(config)
        @index = config["index"].to_i
        VCAP::Logging.setup_from_config(config["logging"])
        @logger = VCAP::Logging.logger("collector")

        @tsdb_host = config["tsdb"]["host"]
        @tsdb_port = config["tsdb"]["port"]
        @nats_uri = config["mbus"]

        intervals = config["intervals"]

        @discover_interval = intervals["discover"]
        @varz_interval = intervals["varz"]
        @healthz_interval = intervals["healthz"]
        @prune_interval = intervals["prune"]
        @nats_ping_interval = intervals["nats_ping"]
        @local_metrics_interval = intervals["local_metrics"]
      end
    end
  end
end
