require 'queuel/iron_mq/poller'
require 'queuel/base/queue'
require 'forwardable'
require 'securerandom'
module Queuel
  module IronMq
    class Queue < Base::Queue
      extend Forwardable
      def_delegators :queue_connection, :peek

      def peek(options = {})
        Array(queue_connection.peek(options))
      rescue Rest::HttpError => e
        Queuel.logger.error(e.message)
        return nil
      end

      # For IronMQ it should just be (message)
      def push(message, options = {})
        queue_connection.post build_push_message(message, options)
      end

      def size
        queue_connection.size
      end

      private
      def pop_bare_message(options = {})
        queue_connection.get options.merge(default_get_message_options)
      end

      def queue_connection
        @queue_connection ||= client.queue(name)
      end

      def default_get_message_options
        { c: SecureRandom.hex }
      end
    end
  end
end
