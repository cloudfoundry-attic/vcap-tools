$:.unshift(File.expand_path(".", File.dirname(__FILE__)))

require "rubygems"
require "bundler/setup"

require "eventmachine"
require "vcap/logging"
require "cf_message_bus/message_bus"

module RouterRegistrar
  class Config
    class << self
      attr_accessor :logger, :message_bus_uri, :uri, :host, :port, :tags

      def configure(config)
        VCAP::Logging.setup_from_config(config["logging"])
        @logger = VCAP::Logging.logger("router_registrar")

        @message_bus_uri = config["mbus"]

        @uri = config["uri"]
        @host = config["host"]
        @port = config["port"]
        @tags = config["tags"]
      end
    end
  end

  class RouterRegistrar
    ROUTER_START_TOPIC = "router.start"
    ROUTER_REGISTER_TOPIC = "router.register"
    ROUTER_UNREGISTER_TOPIC = "router.unregister"

    def initialize
      @logger = Config.logger

      @registration_message = {
        :host => Config.host,
        :port => Config.port,
        :uris => Array(Config.uri),
        :tags => Config.tags
      }

      @message_bus = CfMessageBus::MessageBus.new(uri: Config.message_bus_uri)
      
      @logger.info("Connected to NATS")
      @message_bus.subscribe(ROUTER_START_TOPIC)  do |message|
        send_registration_message
        EM.cancel_timer(@registration_timer) if @registration_timer
        @registration_timer = EM.add_periodic_timer(message[:minimumRegisterIntervalInSeconds]) do
          send_registration_message
        end
      end
      send_registration_message
    end

    def shutdown(&block)
      send_unregistration_message(&block)
    end

    def send_registration_message
      @logger.info("Sending registration: #{@registration_message}")
      @message_bus.publish(ROUTER_REGISTER_TOPIC, @registration_message)
    end

    def send_unregistration_message(&block)
      @logger.info("Sending unregistration: #{@registration_message}")
      @message_bus.publish(ROUTER_UNREGISTER_TOPIC, @registration_message, &block)
    end

  end

end