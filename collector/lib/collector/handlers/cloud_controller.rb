require 'matrix'

module Collector
  class Handler
    class CloudController < Handler
      register Components::CLOUD_CONTROLLER_COMPONENT

      DHMS_IN_SECS = [24 * 60 * 60, 60 * 60, 60, 1].freeze

      def process(context)
        varz = context.varz


        varz["vcap_sinatra"]["requests"].each do |key, value|
          send_metric("cc.requests.#{key}", value, context)
        end

        aggregate_http_status(varz).each do |key, value|
          send_metric("cc.http_status.#{key}", value, context)
        end

        varz["vcap_sequel"]["connection_pool"].each do |key, value|
          send_metric("cc.db.pool.#{key}", value, context)
        end

        send_metric("cc.uptime", uptime_in_seconds(varz), context)
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