module Collector
  # TSDB connection for sending metrics
  class TsdbConnection < EventMachine::Connection

    def post_init
      @logger = Config.logger
    end

    def connection_completed
      @logger.info("Connected to TSDB server")
    end

    def unbind
      @logger.warn("Connection to TSDB server dropped.")

      EM.add_timer(1.0) do
        begin
          reconnect(@ip, @port)
        rescue EventMachine::ConnectionError => e
          @logger.warn(e)
          unbind
        end
      end
    end

    def receive_data(data)
      @logger.debug("Received from TSDB: #{data}")
    end

  end
end
