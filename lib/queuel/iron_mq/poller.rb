module Queuel
  module IronMq
    class Poller < Base::Poller
      # Public: poll
      private

      def built_options
        options.merge default_options # intentional direction, force defaults
      end

      def default_options
        { n: 1 }
      end

      def peek_options
        { n: self.workers }
      end
    end
  end
end
