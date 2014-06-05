require 'queuel/base/queue'
require 'forwardable'
module Queuel
  module SQS
    class Queue < Base::Queue
      extend Forwardable

      attr_accessor :credentials

      def initialize(client, queue_name, credentials={})
        self.client = client
        self.name = queue_name
        self.credentials = credentials
      end


      def push(message, options = {})
        built_message = build_push_message message, credentials.merge(options)
        queue_connection.send_message built_message
      end

      def approximate_number_of_messages
        queue_connection.approximate_number_of_messages
      end

      def size
        approximate_number_of_messages
      end

      private

      def build_new_message(bare_message, options = {})
        message_klass.new(bare_message, credentials)
      end

      def pop_bare_message(options = {})
        queue_connection.receive_message options
      end

      def queue_connection
        @queue_connection ||= client.queues.named(name)
      end
    end
  end
end
