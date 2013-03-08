require 'time'
require 'aws-sdk'

module Collector
  class Historian
    class CloudWatch
      def initialize(access_key_id, access_secret_key)
        AWS.config(
            :access_key_id => access_key_id,
            :secret_access_key => access_secret_key)
      end

      def send_data (data)
        time = data.fetch(:timestamp, Time.now.to_i)
        dimensions = data[:tags].map {|key, value| {name: key.to_s, value: value.to_s } }

        dimensions << {name: "name", value: "#{data[:tags][:job]}/#{data[:tags][:index]}"}
        dimensions << {name: "deployment", value: "dev113cw"}  # hardcode deployment to "staging"

        metric = {
            namespace: "CF/Collector",
            metric_data: [
                {
                    metric_name: data[:key].to_s,
                    value: data[:value].to_s,
                    timestamp: Time.at(time).utc.iso8601,
                    dimensions: dimensions
                }]
        }

        EventMachine.defer do
          cloud_watch = AWS::CloudWatch.new
          cloud_watch.put_metric_data metric
        end
      end
    end
  end
end