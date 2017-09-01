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

      def push(message, options = {})
        raise NotImplementedError, "must implement #push"
      end

      def pop(options = {}, &block)
        message_options, engine_options = Queuel::Hash.new(options).partition { |(k,_)| message_option_keys.include? k.to_s }
        bare_message = pop_bare_message(engine_options)
        unless bare_message.nil?
          build_new_message(bare_message, message_options).tap { |message|
            if block_given? && message.present?
              message.delete if yield(message)
            end
          }
        end
      end

      def receive(options = {}, &block)
        poller_klass.new(self, block, options, thread_count).poll
      end

      def size
        raise NotImplementedError, "must implement #size"
      end

      def max_pool_tasks
        Queuel.max_pool_tasks || nil
      end

      private
      attr_accessor :client
      attr_accessor :name

      def message_option_keys
        %w[encode encoder decode decoder]
      end

      def build_push_message(message, options = {})
        build_new_message(nil, options).tap { |m|
          m.body = message
        }.raw_body
      end

      def thread_count
        Queuel.receiver_threads || 1
      end

      def pop_bare_message(options = {})
        raise NotImplementedError, "must implement bare Message getter"
      end

      def build_new_message(bare_message, options = {})
        message_klass.new(bare_message, options)
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
