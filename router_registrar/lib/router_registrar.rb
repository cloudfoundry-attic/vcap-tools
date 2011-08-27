$:.unshift(File.expand_path(".", File.dirname(__FILE__)))

require "rubygems"
require "bundler/setup"

require "eventmachine"
require "nats/client"
require "vcap/logging"

module RouterRegistrar

  class Config
    class << self
      [:logger, :nats_uri, :uri, :host, :port, :tags].each { |option| attr_accessor option }

      def configure(config)
        VCAP::Logging.setup_from_config(config["logging"])
        @logger = VCAP::Logging.logger("router_registrar")

        @nats_uri = config["mbus"]

        @uri = config["uri"]
        @host = config["host"]
        @port = config["port"]
        @tags = config["tags"]
      end
    end
  end

  class RouterRegistrar
    def initialize
      @logger = Config.logger

      @registration_message = Yajl::Encoder.encode({
        :host => Config.host,
        :port => Config.port,
        :uris => [Config.uri],
        :tags => Config.tags
      })

      NATS.on_error do |e|
        @logger.fatal("Exiting, NATS error")
        @logger.fatal(e)
        exit
      end

      @nats = NATS.connect(:uri => Config.nats_uri) do
        @logger.info("Connected to NATS")
        @nats.subscribe("router.start") do
          send_registration_message
        end
        send_registration_message
      end

      def send_registration_message
        @logger.info("Sending registration: #{@registration_message}")
        @nats.publish("router.register", @registration_message)
      end
    end

  end

end