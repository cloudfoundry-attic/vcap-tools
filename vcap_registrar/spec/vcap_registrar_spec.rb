require_relative "../lib/vcap_registrar"
require "cf_message_bus/mock_message_bus"

module VcapRegistrar
  describe VcapRegistrar do
    let(:message_bus) { CfMessageBus::MockMessageBus.new }
    let(:bus_uri) { "a message bus uri" }
    let(:config) do
      {
        "mbus" => bus_uri,
        "host" => "registrar.host",
        "port" => 98765,
        "uri" => "fancyuri",
        "tags" => "taggy goodness",
        "varz" => {}
      }
    end

    before do
      EM.stub(:cancel_timer)
      Config.configure(config)
      Config.stub(:logger).and_return(double(:logger, info: nil, error: nil, debug: nil))
      CfMessageBus::MessageBus.stub(:new).with(uri: bus_uri).and_return(message_bus)
    end

    describe "#register_with_router" do
      let(:registration_message) do
        {
          host: config["host"],
          port: config["port"],
          uris: Array(config["uri"]),
          tags: config["tags"]
        }
      end

      it "registers routes immediately" do
        subject.register_with_router
        expect(message_bus).to have_published_with_message("router.register", registration_message)
      end

      it "registers upon a router.start message" do
        EM.should_receive(:add_periodic_timer).with(33)

        subject.register_with_router

        message_bus.clear_published_messages

        message_bus.publish("router.start", {minimumRegisterIntervalInSeconds: 33})

        expect(message_bus).to have_published_with_message("router.register", registration_message)
      end

      it "greets the router" do
        EM.should_receive(:add_periodic_timer).with(33)

        subject.register_with_router

        message_bus.clear_published_messages

        message_bus.respond_to_request("router.greet", {minimumRegisterIntervalInSeconds: 33})
      end

      it "periodically registers with the router" do
        EM.should_receive(:add_periodic_timer).with(33).and_return(:periodic_timer)
        subject.register_with_router
        message_bus.publish("router.start", {minimumRegisterIntervalInSeconds: 33})
      end

      it "clears an existing timer when registering a new one" do
        subject.register_with_router

        EM.should_receive(:add_periodic_timer).with(33).and_return(:periodic_timer)
        message_bus.publish("router.start", {minimumRegisterIntervalInSeconds: 33})

        EM.should_receive(:cancel_timer).with(:periodic_timer)
        EM.should_receive(:add_periodic_timer).with(24)
        message_bus.publish("router.start", {minimumRegisterIntervalInSeconds: 24})
      end
    end
  end
end