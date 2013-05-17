module Queuel
  module Base
    class Queue
      extend Introspect

      def initialize(client, queue_name)
        self.client = client
        self.name = queue_name
      end

      def peek(options = {})
        raise NotImplementedError, "must implement #peek"
      end

      def push(message)
        raise NotImplementedError, "must implement #push"
      end

      def pop(options = {}, &block)
        bare_message = pop_bare_message(options)
        unless bare_message.nil?
          build_new_message(bare_message).tap { |message|
            if block_given? && !message.nil?
              yield message
              message.delete
            end
          }
        end
      end

      def receive(options = {}, &block)
        poller_klass.new(thread_count, self, options, block).poll
      end

      private
      attr_accessor :client
      attr_accessor :name

      def thread_count
        Queuel.receiver_threads || 1
      end

      def pop_bare_message(options = {})
        raise NotImplementedError, "must implement bare Message getter"
      end

      def build_new_message(bare_message)
        message_klass.new(bare_message)
      end

      def message_klass
        self.class.const_with_nesting("Message")
      end

      def poller_klass
        self.class.const_with_nesting("Poller")
      end
    end
  end
end
