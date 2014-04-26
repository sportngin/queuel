require "forwardable"
module Queuel
  module RabbitMq
    class Engine < Base::Engine
      extend Forwardable
      def_delegators :Queuel, :logger

      def queue(which_queue)
        memoized_queues[which_queue.to_s] ||= queue_klass.new(client, which_queue, credentials)
      end

      private

      def client_klass
        try_load(::AMQP::Channel, 'amqp')
      end
    end
  end
end
