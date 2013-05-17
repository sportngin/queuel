require 'thread/pool'
module Queuel
  module Base
    class Poller
      def initialize(workers = 1, queue, options, block)
        self.workers = workers
        self.queue = queue
        self.options = options || {}
        self.block = block
        self.tries = 0
        self.continue_looping = true
      end

      def poll
        register_trappers
        master = master_thread
        master.join
      rescue SignalException => e
        shutdown
      end

      protected
      attr_accessor :tries
      attr_accessor :workers

      private
      attr_accessor :queue
      attr_accessor :args
      attr_accessor :options
      attr_accessor :block
      attr_accessor :continue_looping

      def register_trappers
        trap(:SIGINT) { shutdown }
      end

      def shutdown
        quit_looping!
        master.kill
        pool.shutdown
      end

      def pool
        @pool ||= Thread.pool workers
      end

      def master_thread
        Thread.new do
          master_looper
        end
      end

      def peek_options
        {}
      end

      def peek
        queue.peek peek_options
      end

      def queue_size # TODO optionize the peek options
        Array(peek).size
      end

      def process_off_peek
        mem_queue_size = queue_size
        if mem_queue_size > 0
          reset_tries
          mem_queue_size.times do
            process_on_thread
          end
        else
          tried
          quit_looping! if quit_on_empty?
        end
      end

      def process_on_thread
        pool.process do
          process_message
        end
      end

      def process_message
        message = pop_new_message
        message.delete if block.call message
      rescue => e
        puts e
        puts e.backtrace.join "\n"
      end

      def master_looper
        loop do
          break unless continue_looping?
          process_off_peek
          sleep sleep_time
        end
      end

      def built_options
        raise NotImplementedError
      end

      def continue_looping?
        !!continue_looping
      end

      def break_if_nil?
        !!options[:break_if_nil]
      end
      alias quit_on_empty? break_if_nil?

      def quit_looping!
        self.continue_looping = false
      end

      def pop_new_message
        queue.pop built_options
      end

      def start_sleep_time
        0
      end

      def increment_sleep_time
        0.1
      end

      def sleep_time
        tries < 30 ? ((start_sleep_time + increment_sleep_time) * tries) : 3
      end

      def reset_tries
        self.tries = 0
      end

      def tried
        self.tries += 1
      end
    end
  end
end
