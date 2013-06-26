$:.unshift(File.expand_path(".", File.dirname(__FILE__)))

require "rubygems"
require "bundler/setup"

require "eventmachine"
require "vcap/logging"
require "securerandom"
require "cf_message_bus/message_bus"

module VcapRegistrar
  class Config
    class << self
      attr_accessor :logger, :message_bus_uri, :type, :host, :port, :username, :password, :uri, :tags, :uuid, :index

      def configure(config)
        @logger = VCAP::Logging.logger("vcap_registrar")

        @message_bus_uri = config["mbus"]

        @host = config["host"]
        @port = config["port"]
        @uri = config["uri"]
        @tags = config["tags"]
        @type = config["varz"]["type"]
        @username = config["varz"]["username"]
        @password = config["varz"]["password"]
        @uuid = config["varz"]["uuid"] || SecureRandom.uuid
        @index = config["index"] || 0
      end
    end
  end

  class VcapRegistrar
    DISCOVER_TOPIC = "vcap.component.discover"
    ANNOUNCE_TOPIC = "vcap.component.announce"
    ROUTER_START_TOPIC = "router.start"
    ROUTER_REGISTER_TOPIC = "router.register"
    ROUTER_UNREGISTER_TOPIC = "router.unregister"

    def initialize
      @logger = Config.logger
      @message_bus = CfMessageBus::MessageBus.new(uri: Config.message_bus_uri)
    end

    def register_varz_credentials()
      @discover_msg = {
        :type => Config.type,
        :host => "#{Config.host}:#{Config.port}",
        :index => Config.index,
        :uuid => "#{Config.index}-#{Config.uuid}",
        :credentials => [Config.username, Config.password]
      }

      if Config.username.nil? || Config.password.nil?
        @logger.error("Could not register nil varz credentials")
      else
        @logger.info("Connected to NATS - varz registration")

        @message_bus.subscribe(DISCOVER_TOPIC) do |msg, reply|
          @logger.debug("Received #{DISCOVER_TOPIC} publishing #{reply.inspect} #{@discover_msg.inspect}")
          @message_bus.publish(reply, @discover_msg)
        end

        @logger.info("Announcing start up #{ANNOUNCE_TOPIC}")
        @message_bus.publish(ANNOUNCE_TOPIC, @discover_msg)
      end
    end


    def register_with_router()
      @registration_message = {
        :host => Config.host,
        :port => Config.port,
        :uris => Array(Config.uri),
        :tags => Config.tags
      }

      @logger.info("Connected to NATS - router registration")

      @message_bus.subscribe(ROUTER_START_TOPIC) do |message|
        @logger.debug("Sending registration: #{@registration_message}")
        send_registration_message
        EM.cancel_timer(@registration_timer) if @registration_timer
        @registration_timer = EM.add_periodic_timer(message[:minimumRegisterIntervalInSeconds]) do
          send_registration_message
        end
      end
      @logger.info("Sending registration: #{@registration_message}")
      send_registration_message
    end

    def shutdown(&block)
      send_unregistration_message(&block)
    end

    def send_registration_message
      @message_bus.publish(ROUTER_REGISTER_TOPIC, @registration_message)
    end

    def send_unregistration_message(&block)
      @logger.info("Sending unregistration: #{@registration_message}")
      @message_bus.publish(ROUTER_UNREGISTER_TOPIC, @registration_message, &block)
    end
  end
end
