module Queuel
  NoQueueGivenError = Class.new StandardError
  class Client
    def initialize(engine, credentials, init_queue = nil)
      self.engine = engine
      self.credentials = credentials
      self.given_queue = init_queue
    end

    [:push, :pop, :receive].each do |operation|
      define_method(operation) do |*args|
        with_queue { queue_connection.public_send(operation, *args) }
      end
    end

    def with(change_queue = nil)
      self.clone.tap { |client| client.given_queue = change_queue }
    end

    def queue
      bare = (given_queue || Queuel.default_queue)
      bare.to_s unless bare.nil?
    end

    protected
    attr_accessor :given_queue

    private

    def with_queue
      if queue.nil? || queue.to_s.strip.empty?
        raise NoQueueGivenError, "Must select a queue with #with or set a default_queue"
      else
        yield
      end
    end

    def queue_connection
      engine_client.queue queue
    end

    def engine_client
      @engine_client ||= engine.new credentials
    end

    attr_accessor :credentials
    attr_accessor :engine
  end
end
