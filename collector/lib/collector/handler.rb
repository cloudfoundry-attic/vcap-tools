# Copyright (c) 2009-2012 VMware, Inc.

module Collector
  # Varz metric handler
  #
  # It's used for processing varz from jobs and publishing them to the metric collector (Historian)
  # server
  class Handler
    @handler_map = {}

    class << self
      # @return [Hash<String, Handler>] hash of jobs to {Handler}s
      attr_accessor :handler_map

      # Registers the {Handler} for a job type.
      #
      # @param [String, Symbol] job the job name
      def register(job)
        job = job.to_s
        Config.logger.info("Registering handler: #{self} for job: #{job}")
        raise "Job: #{job} already registered" if Handler.handler_map[job]
        Handler.handler_map[job] = self
      end

      # Retrieves a {Handler} for the job type with the provided context. Will
      # default to the generic one if the job does not have a handler
      # registered.
      #
      # @param [Collector::Historian] historian the historian to use for
      #   writing metrics
      # @param [String] job the job name
      # @param [Fixnum] index the job index
      # @param [Fixnum] now the timestamp of when the metrics were collected
      # @return [Handler] the handler for this job from the handler map or the
      #   default one
      def handler(historian, job, index, now)
        if handler_class = Handler.handler_map[job]
          handler_class.new(historian, job, index, now)
        else
          Handler.new(historian, job, index, now)
        end
      end
    end

    # @return [String] job name
    attr_accessor :job

    # @return [Fixnum] job index
    attr_accessor :index

    # @return [Fixnum] timestamp when metrics were collected
    attr_accessor :now

    # Creates a new varz handler
    #
    # @param [Collector::Historian] historian
    # @param [String] job the job for this varz
    # @param [Fixnum] index the index for this varz
    # @param [Fixnum] now the timestamp when it was collected
    def initialize(historian, job, index, now)
      @historian = historian
      @job = job
      @index = index
      @now = now
      @logger = Config.logger
    end

    # Processes varz in the context of the collection. Subclasses
    # should override this.
    #
    # @param [Hash] varz the varzs collected for this job
    def process(varz)
    end

    # Called by the collector to process the varz. Processes common
    # metric data and then calls process() to add subclass behavior.
    def do_process(varz, job_tags)
      # TODO: "mem" probably isn't used and should be removed
      send_metric("mem", varz["mem"] / 1024, job_tags) if varz["mem"]
      
      send_metric("mem_free_bytes", varz["mem_free_bytes"], job_tags) if varz["mem_free_bytes"]
      send_metric("mem_used_bytes", varz["mem_used_bytes"], job_tags) if varz["mem_used_bytes"]
      send_metric("cpu_load_avg", varz["cpu_load_avg"], job_tags) if varz["cpu_load_avg"]

      process(varz)
    end

    # Default implementation of is_healthy which is used
    # to check to see if /healthz returns the right value
    # This is necessary because, you know, somethings need
    # to return json and others 'ok'. I'm looking at you gorouter.
    # Override this method in handlers that need something
    # more specific
    def is_healthy?(ok)
      ok.strip.downcase == "ok"
    end

    # Sends the metric to the metric collector (historian)
    #
    # @param [String] name the metric name
    # @param [String, Fixnum] value the metric value
    # @param [Hash] tags the metric tags
    def send_metric(name, value, tags = {})
      @historian.send_data({
                               key: name,
                               timestamp: @now,
                               value: value,
                               tags: tags.merge(job: @job, index: @index)
                           })
    end

    # Sends latency metrics to the metric collector (historian)
    #
    # @param [String] name the metric name
    # @param [Hash] value the latency metric value
    # @param [Hash] tags the metric tags
    def send_latency_metric(name, value, tags = {})
      if value && value["samples"] && value["samples"] > 0
        send_metric(name, value["value"] / value["samples"], tags)
      end
    end
  end
end