require 'queuel/iron_mq/poller'
require 'queuel/base/queue'
require 'forwardable'
module Queuel
  module IronMq
    class Queue < Base::Queue
      extend Forwardable
      def_delegators :queue_connection, :peek

      def peek(options = {})
        Array(queue_connection.peek(options))
      end

      # For IronMQ it should just be (message)
      def push(message, options = {})
        queue_connection.post build_push_message(message, options)
      end

      private
      def pop_bare_message(options = {})
        queue_connection.get options
      end

      def queue_connection
        @queue_connection ||= client.queue(name)
      end
    end
  end
end
