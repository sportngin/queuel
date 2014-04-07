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
        if defined?(::AWS::SQS)
          ::AWS::SQS
        else
          begin
            logger.info "Loading AWS SDK..."
            require 'aws-sdk'
            ::AWS::SQS
          rescue LoadError
            logger.error "Couldn't find aws_sdk gem"
            raise(AWSSDKMissingError)
          end
        end
      end
    end
  end
end
