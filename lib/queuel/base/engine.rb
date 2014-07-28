module Queuel
  module Base
    class Engine
      extend Introspect
      def self.inherited(klass)
        klass.class_eval do
          def queue_klass
            self.class.const_with_nesting "Queue"
          end
        end
      end

      def initialize(credentials = {})
        self.credentials = credentials
        self.bucket_name = credentials[:bucket_name]
        self.memoized_queues = {}
      end

      def queue(which_queue)
        memoized_queues[which_queue.to_s] ||= queue_klass.new(client, which_queue)
      end

      private
      attr_accessor :credentials
      attr_accessor :bucket_name
      attr_accessor :memoized_queues

      def client
        @client ||= client_klass.new credentials
      end

      def client_klass
        raise NotImplementedError, "Must define a Queue class"
      end

      def try_load(klass, gem_name)
        if defined?(klass)
          klass
        else
          begin
            logger.info "Loading #{klass}..."
            require gem_name
            klass
          rescue LoadError
            logger.error "Couldn't find #{gem_name} gem"
          end
        end
      end

    end
  end
end
