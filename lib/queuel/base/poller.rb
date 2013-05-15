require 'timeout'
module Queuel
  module Base
    class Poller
      def initialize(queue, options, block)
        self.queue = queue
        self.options = options || {}
        self.block = block
        self.tries = 0
        self.continue_looping = true
      end

      def poll
        choose_looper do |msg|
          if msg.nil?
            tried
            quit_looping! if break_if_nil? || maxed_tried?
            sleep(sleep_time)
          else
            reset_tries
            block.call msg
            msg.delete
          end
          !msg.nil?
        end
      end

      protected
      attr_accessor :tries

      private
      attr_accessor :queue
      attr_accessor :args
      attr_accessor :options
      attr_accessor :block
      attr_accessor :continue_looping

      def built_options
        raise NotImplementedError
      end

      def choose_looper(&loop_block)
        timeout? ? timeout_looper(loop_block) : looper(loop_block)
      end

      def timeout_looper(loop_block)
        Timeout.timeout(timeout) { looper(loop_block) }
      rescue Timeout::Error
        false
      end

      def looper(loop_block)
        while continue_looping? do
          loop_block.call(pop_new_message)
        end
      end

      def continue_looping?
        !!continue_looping
      end

      def quit_looping!
        self.continue_looping = false
      end

      def timeout
        options[:poll_timeout].to_i
      end

      def timeout?
        timeout > 0
      end

      def pop_new_message
        queue.pop built_options
      end

      def start_sleep_time
        0.1
      end

      def sleep_time
        tries < 30 ? (start_sleep_time * tries) : 3
      end

      def reset_tries
        self.tries = 0
      end

      def maxed_tried?
        tries >= max_fails if max_fails_given?
      end

      def max_fails_given?
        max_fails > 0
      end

      def max_fails
        options[:max_consecutive_fails].to_i
      end

      def tried
        self.tries += 1
      end

      def break_if_nil?
        !!options.fetch(:break_if_nil, false)
      end
    end
  end
end
