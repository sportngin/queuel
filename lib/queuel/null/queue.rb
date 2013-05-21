require 'queuel/null/poller'
module Queuel
  module Null
    class Queue < Base::Queue
      def peek(options = {})
        []
      end

      def push(message, options = {})
      end

      # Nullify
      def pop(options = {}, &block)
      end
    end
  end
end
