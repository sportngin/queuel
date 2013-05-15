require 'queuel/iron_mq/poller'
module Queuel
  module IronMq
    class Queue < Base::Queue
      # For IronMQ it should just be (message)
      def push(*args)
        queue_connection.post *args
      end

      private
      def pop_bare_message(*args)
        queue_connection.get *args
      end

      def queue_connection
        @queue_connection ||= client.queue(name)
      end
    end
  end
end
