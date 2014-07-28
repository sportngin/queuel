require "forwardable"
module Queuel
  module SQS
    class Engine < Base::Engine
      extend Forwardable
      def_delegators :Queuel, :logger

      AWSSDKMissingError = Class.new(StandardError)

      def queue(which_queue)
        memoized_queues[which_queue.to_s] ||= queue_klass.new(client, which_queue, credentials)
      end

      private

      def client_klass
        try_load(::AWS::SQS, 'aws-sdk')
      end
    end
  end
end
