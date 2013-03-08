require 'collector/tsdb_connection'

module Collector
  class Historian
    class Tsdb
      attr_reader :connection
      def initialize(host, port)
        @host = host
        @port = port
        @connection = EventMachine.connect(@host, @port, TsdbConnection)
      end

      def send_data(properties)
        tags = properties[:tags].collect { |tag| tag.join("=") }.sort.join(" ")
        command = "put #{properties[:key]} #{properties[:timestamp]} #{properties[:value]} #{tags}\n"

        ::Collector::Config.logger.debug1(command)
        @connection.send_data(command)
      end
    end
  end
end