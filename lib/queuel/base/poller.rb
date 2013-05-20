require 'thread'
require 'thread/pool'
module Queuel
  module Base
    class Poller
      def initialize(queue, param_block, options = {}, workers = 1)
        self.workers = workers
        self.queue = queue
        self.options = options || {}
        self.inst_block = param_block
        self.tries = 0
        self.continue_looping = true
      end

      def poll
        register_trappers
        self.master = master_thread
        master.join
      rescue SignalException => e
        shutdown
      end

      protected
      attr_accessor :tries
      attr_accessor :workers
      attr_accessor :inst_block

      private
      attr_accessor :master
      attr_accessor :queue
      attr_accessor :args
      attr_accessor :options
      attr_accessor :continue_looping

      def register_trappers
        trap(:SIGINT) { shutdown }
        trap(:INT) { shutdown }
      end

      def shutdown
        pool.shutdown
        master.kill
        quit_looping!
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
        register_trappers
        message = pop_new_message
        message.delete if self.inst_block.call message
      rescue => e
        puts e
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
