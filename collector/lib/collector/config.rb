module Collector
  # Singleton config used throughout
  class Config
    class << self
      [:logger, :tsdb_host, :tsdb_port, :nats_uri,
       :discover_interval, :varz_interval, :healthz_interval, :prune_interval].each { |option| attr_accessor option }

      # Configures the various attributes
      #
      # @param [Hash] config the config Hash
      def configure(config)
        VCAP::Logging.setup_from_config(config["logging"])
        @logger = VCAP::Logging.logger("collector")

        @tsdb_host = config["tsdb"]["host"]
        @tsdb_port = config["tsdb"]["port"]
        @nats_uri = config["mbus"]

        @discover_interval = config["intervals"]["discover"]
        @varz_interval = config["intervals"]["varz"]
        @healthz_interval = config["intervals"]["healthz"]
        @prune_interval = config["intervals"]["prune"]
      end
    end
  end
end