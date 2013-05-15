module Queuel
  module Base
    class Queue
      extend BaseKlass

      def initialize(client, queue_name)
        self.client = client
        self.name = queue_name
      end

      def push(*args)
        raise NotImplementedError, "must implement #push"
      end

      def pop(*args, &block)
        bare_message = pop_bare_message(*args)
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
        poller_klass.new(self, options, block).poll
      end

      private
      attr_accessor :client
      attr_accessor :name

      def pop_bare_message(*args)
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
