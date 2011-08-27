$:.unshift(File.expand_path(".", File.dirname(__FILE__)))

require "set"

require "rubygems"
require "bundler/setup"

require "em-http-request"
require "eventmachine"
require "nats/client"
require "vcap/logging"

require "collector/config"
require "collector/handler"
require "collector/tsdb_connection"

module Collector

  CLOUD_CONTROLLER_COMPONENT = "CloudController"
  DEA_COMPONENT = "DEA"
  HEALTH_MANAGER_COMPONENT = "HealthManager"
  ROUTER_COMPONENT = "Router"

  # Varz collector
  class Collector

    ANNOUNCE_SUBJECT = "vcap.component.announce"
    DISCOVER_SUBJECT = "vcap.component.discover"

    # Creates a new varz collector based on the {Config} settings.
    def initialize
      Dir[File.join(File.dirname(__FILE__), "..", "lib", "collector", "handlers", "*.rb")].each do |file|
        require File.join("collector", "handlers", File.basename(file, File.extname(file)))
      end

      @logger = Config.logger

      @components = {}
      @core_components = Set.new([CLOUD_CONTROLLER_COMPONENT, DEA_COMPONENT,
                                  HEALTH_MANAGER_COMPONENT, ROUTER_COMPONENT])

      @tsdb_connection = EventMachine.connect(Config.tsdb_host, Config.tsdb_port, TsdbConnection)

      NATS.on_error do |e|
        @logger.fatal("Exiting, NATS error")
        @logger.fatal(e)
        exit
      end

      @nats = NATS.connect(:uri => Config.nats_uri) do
        # Send initially to discover what's already running
        @nats.subscribe(ANNOUNCE_SUBJECT) {|message| process_component_discovery(message)}

        @inbox = NATS.create_inbox
        @nats.subscribe(@inbox) {|message| process_component_discovery(message)}

        @nats.publish(DISCOVER_SUBJECT, "", @inbox)

        setup_timers
      end
    end

    # Configures the periodic timers for collecting varzs.
    def setup_timers
      EM.add_periodic_timer(Config.discover_interval) { @nats.publish(DISCOVER_SUBJECT, "", @inbox) }
      EM.add_periodic_timer(Config.varz_interval) { fetch_varz }
      EM.add_periodic_timer(Config.healthz_interval) { fetch_healthz }
      EM.add_periodic_timer(Config.prune_interval) { prune_components }
    end

    # Processes a discovered component message, recording it's location for varz/healthz probes.
    #
    # @param [Hash] message the discovery message
    def process_component_discovery(message)
      message = Yajl::Parser.parse(message)
      if message["index"]
        @logger.debug1("Found #{message["type"]}/#{message["index"]} @ #{message["host"]} #{message["credentials"]}")
        instances = (@components[message["type"]] ||= {})
        instances[message["index"]] = {
          :host => message["host"],
          :credentials => message["credentials"],
          :timestamp => Time.now.to_i
        }
      end
    rescue Exception => e
      @logger.warn("Error discovering components: #{e.message}")
      @logger.warn(e)
    end

    # Prunes components that haven't been heard from in a while
    def prune_components
      @components.each do |_, instances|
        instances.delete_if { |_, component| Time.now.to_i - component[:timestamp] > Config.prune_interval }
      end

      @components.delete_if { |_, instances| instances.empty? }
    rescue => e
      @logger.warn("Error pruning components: #{e.message}")
      @logger.warn(e)
    end

    # Fetches the varzs from all the components and calls the proper {Handler} to record the metrics in the TSDB server
    def fetch_varz
      @components.each do |job, instances|
        instances.each do |index, instance|
          http = EventMachine::HttpRequest.new("http://#{instance[:host]}/varz").get(
                  :head => {"authorization" => instance[:credentials]})
          http.errback do
            @logger.warn("Failed fetching varz from: #{instance[:host]}")
          end
          http.callback do
            begin
              varz = Yajl::Parser.parse(http.response)
              now = Time.now.to_i

              handler = Handler.handler(@tsdb_connection, job, index, now)
              handler.send_metric("mem", varz["mem"] / 1024, get_job_tags(job))
              handler.process(varz)
            rescue => e
              @logger.warn("Error processing varz: #{e.message}")
              @logger.warn(e)
            end
          end
        end
      end
    end

    # Fetches the healthz from all the components and calls the proper {Handler} to record the metrics in the
    # TSDB server
    def fetch_healthz
      @components.each do |job, instances|
        instances.each do |index, instance|
          http = EventMachine::HttpRequest.new("http://#{instance[:host]}/healthz").get(
                  :head => {"authorization" => instance[:credentials]})
          http.errback do
            @logger.warn("Failed fetching healthz from: #{instance[:host]}")
          end
          http.callback do
            begin
              now = Time.now.to_i
              handler = Handler.handler(@tsdb_connection, job, index, now)
              handler.send_metric("healthy", http.response.strip.downcase == "ok" ? 1 : 0, get_job_tags(job))
            rescue => e
              @logger.warn("Error processing healthz: #{e.message}")
              @logger.warn(e)
            end
          end
        end
      end
    end

    # Generates the common tags used for generating common (memory, health, etc.) metrics.
    #
    # @param [String] type the job type
    # @return [Hash<Symbol, String>] tags for this job type
    def get_job_tags(type)
      tags = {}
      if @core_components.include?(type)
        tags[:role] = "core"
      elsif type =~ /(?:(^[^-]+)-Service)|(?:(^.*)aaS-(?:(?:Node)|(?:Provisioner)))/
        tags[:role] = "service"
        tags[:service_type] = $1 || $2
      end
      tags
    end

  end
end