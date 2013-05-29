require 'time'
require 'dogapi'

module Collector
  class Historian
    class DataDog
      def initialize(api_key, application_key)
        @dog_client = Dogapi::Client.new(api_key, application_key)
      end

      def send_data(data)
        name = "cf.collector.#{data[:key].to_s}"
        time = data.fetch(:timestamp, Time.now.to_i)
        point = [Time.at(time), data[:value]]
        tags = data[:tags].flat_map do |key, value|
          Array(value).map do |v|
            "#{key}:#{v}"
          end
        end

        EventMachine.defer do
          @dog_client.emit_points(name, [point], tags: tags)
        end
      end
    end
  end
end
