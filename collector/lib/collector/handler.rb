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
      # @param [Hash] varz the values from the remote server /varz
      # @return [Handler] the handler for this job from the handler map or the
      #   default one
      def handler(historian, job, index, now, varz)
        if handler_class = Handler.handler_map[job]
          handler_class.new(historian, job, index, now, varz)
        else
          Handler.new(historian, job, index, now, varz)
        end
      end
    end

    # @return [String] job name
    attr_reader :job

    # @return [Fixnum] job index
    attr_reader :index

    # @return [Fixnum] timestamp when metrics were collected
    attr_reader :now

    attr_reader :varz

    # Creates a new varz handler
    #
    # @param [Collector::Historian] historian
    # @param [String] job the job for this varz
    # @param [Fixnum] index the index for this varz
    # @param [Fixnum] now the timestamp when it was collected
    def initialize(historian, job, index, now, varz)
      @historian = historian
      @job = job
      @index = index
      @now = now
      @varz = varz
      @logger = Config.logger
    end

    # Processes varz in the context of the collection. Subclasses
    # should override this.
    #
    # @param [Hash] varz the varzs collected for this job
    def process
    end

    # Subclasses can override this to add additional tags to the metrics
    # submitted.
    #
    # @param [Hash] varz the varzs collected for this job
    # @return [Hash] the key/value tags that will be added to the submission
    def additional_tags
      {}
    end

    # Called by the collector to process the varz. Processes common
    # metric data and then calls process() to add subclass behavior.
    def do_process
      # TODO: "mem" probably isn't used and should be removed
      send_metric("mem", @varz["mem"] / 1024) if @varz["mem"]

      send_metric("mem_free_bytes", @varz["mem_free_bytes"]) if @varz["mem_free_bytes"]
      send_metric("mem_used_bytes", @varz["mem_used_bytes"]) if @varz["mem_used_bytes"]
      send_metric("cpu_load_avg", @varz["cpu_load_avg"]) if @varz["cpu_load_avg"]

      process
    end

    # Sends the metric to the metric collector (historian)
    #
    # @param [String] name the metric name
    # @param [String, Fixnum] value the metric value
    def send_metric(name, value, tags = {})
      tags =  tags.merge(Components.get_job_tags(@job)).merge(additional_tags).merge(job: @job, index: @index)
      @historian.send_data({
                               key: name,
                               timestamp: @now,
                               value: value,
                               tags: tags
                           })
    end

    # Sends latency metrics to the metric collector (historian)
    #
    # @param [String] name the metric name
    # @param [Hash] value the latency metric value
    def send_latency_metric(name, value)
      if value && value["samples"] && value["samples"] > 0
        send_metric(name, value["value"] / value["samples"])
      end
    end
  end
end