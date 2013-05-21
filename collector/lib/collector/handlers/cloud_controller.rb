require 'matrix'

module Collector
  class Handler
    class CloudController < Handler
      register CLOUD_CONTROLLER_COMPONENT

      DHMS_IN_SECS = [24 * 60 * 60, 60 * 60, 60, 1].freeze

      def process(varz)
        varz["vcap_sinatra"]["requests"].each do |key, value|
          send_metric("cc.requests.#{key}", value)
        end

        aggregate_http_status(varz).each do |key, value|
          send_metric("cc.http_status.#{key}", value)
        end

        varz["vcap_sequel"]["connection_pool"].each do |key, value|
          send_metric("cc.db.pool.#{key}", value)
        end

        send_metric("cc.uptime", uptime_in_seconds(varz))
      end

      private

      def uptime_in_seconds(varz)
        uptime_in_human = varz["uptime"].gsub("[dhms]", "").split(":").map(&:to_i)
        (Matrix.row_vector(DHMS_IN_SECS) * Matrix.column_vector(uptime_in_human)).element(0, 0)
      end

      def aggregate_http_status(varz)
        varz["vcap_sinatra"]["http_status"].group_by { |key, _| key[0] }.map do |key, value|
          value = value.inject(0) do |sum, (_, number_of_requests)|
            sum += number_of_requests
          end
          ["#{key}XX", value]
        end
      end
    end
  end
end