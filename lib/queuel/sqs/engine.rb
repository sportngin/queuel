require "queuel/aws_constant_finder"
require "queuel/aws_engine"

module Queuel
  module SQS
    class Engine < Base::Engine
      include AwsEngine

      def queue(which_queue)
        memoized_queues[which_queue.to_s] ||= queue_klass.new(client, which_queue, config)
      end

      private
      def client_klass
        AWSConstantFinder.find(:sqs)::Client
      end
    end
  end
end
