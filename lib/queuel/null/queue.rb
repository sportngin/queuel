require 'queuel/null/poller'
module Queuel
  module Null
    class Queue < Base::Queue
      def push(*)
      end

      # Nullify
      def pop(*args, &block)
      end
    end
  end
end
