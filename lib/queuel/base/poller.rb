require 'thread'
require "thread/pool"
require "forwardable"
module Queuel
  module Base
    class Poller
      extend Forwardable
      def_delegators :Queuel, :logger

      def initialize(queue, param_block, options = {}, workers = 1)
        self.workers = workers
        self.queue = queue
        self.options = options || {}
        self.inst_block = param_block
        self.tries = 0
        self.continue_looping = true
        self.pool_tasks = 0
        self.mutex = Mutex.new
      end

      def poll
        register_trappers
        logger.debug("Beginning Poll...")
        self.master = master_thread
        log_action(:joining, :master) { master.join }
      rescue SignalException => e
        logger.warn "Caught (#{e}), shutting Poller down"
        log_action(:killing, :poller, :warn) { shutdown }
      end

      protected
      attr_accessor :tries
      attr_accessor :workers
      attr_accessor :inst_block
      attr_accessor :mutex
      attr_accessor :pool_tasks

      private
      attr_accessor :master
      attr_accessor :queue
      attr_accessor :args
      attr_accessor :options
      attr_accessor :continue_looping

      def register_trappers
        trap(:SIGINT) { Thread.new{shutdown}.join }
        trap(:INT) { Thread.new{shutdown}.join }
      end

      def log_action(verb, subject, level = :debug)
        verb = verb.to_s.upcase.gsub(/\_/, " ")
        subject = subject.to_s.upcase.gsub(/\_/, " ")
        logger.public_send level, "#{verb} #{subject} START"
        yield
        logger.public_send level, "#{verb} #{subject} COMPLETE"
      end

      def shutdown
        log_action(:shutting_down, :thread_pool) { pool.shutdown }
        log_action(:killing, :master_thread) { master.kill }
        log_action(:killing, :loop) { quit_looping! }
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

        if queue.max_pool_tasks && mem_queue_size > queue.max_pool_tasks
          mem_queue_size = queue.max_pool_tasks
        end

        if mem_queue_size > 0
          reset_tries
          mem_queue_size.times do
            process_on_thread
          end
          GC.start
        else
          tried
          quit_looping! if quit_on_empty?
        end
      end

      def process_on_thread
        pool.process do
          begin
            increment_pool_task_count
            process_message
          ensure
            decrement_pool_task_count
          end unless pool_full?
        end
      end

      def process_message
        register_trappers
        pop_new_message
      rescue => e
        logger.warn "Received #{e} when processing #{message}"
        logger.warn "Backtrace:"
        logger.warn e.backtrace
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
        queue.pop built_options, &inst_block
      end

      def start_sleep_time
        0
      end

      def increment_sleep_time
        0.1
      end

      def sleep_time
        tries < 30 && !pool_full? ? ((start_sleep_time + increment_sleep_time) * tries) : 3
      end

      def reset_tries
        self.tries = 0
      end

      def tried
        self.tries += 1
      end

      def pool_full?
        return false unless queue.max_pool_tasks
        self.mutex.synchronize{
          self.pool_tasks > queue.max_pool_tasks
        }
      end

      def increment_pool_task_count
        self.mutex.synchronize{
          self.pool_tasks += 1
        }
      end

      def decrement_pool_task_count
        self.mutex.synchronize{
          self.pool_tasks -= 1
        }
      end
    end
  end
end
