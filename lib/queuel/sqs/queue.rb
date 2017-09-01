require 'queuel/base/queue'
require 'forwardable'
module Queuel
  module SQS
    class Queue < Base::Queue
      extend Forwardable

      def initialize(client, queue_name, engine_options = {})
        super(client, queue_name)
        @engine_options = engine_options
      end

      def push(message, options = {})
        built_message = build_push_message message, options
        client.send_message queue_url: queue_url, message_body: built_message
      end

      def approximate_number_of_messages
        response = client.get_queue_attributes(queue_url: queue_url, attribute_names: ['ApproximateNumberOfMessages'])
        response.attributes['ApproximateNumberOfMessages'].to_i
      end

      def size
        approximate_number_of_messages
      end

      def delete(message_object)
        client.delete_message(queue_url: queue_url, receipt_handle: message_object.receipt_handle)
      end

      private
      def build_new_message(bare_message, options = {})
        message_klass.new(bare_message, @engine_options.merge(options).merge(queue: self))
      end

      def pop_bare_message(options = {})
        receive_options = options[:receive_message]
        receive_options = {} unless receive_options.is_a?(Hash)
        params = receive_options.merge(queue_url: queue_url,
                                       message_attribute_names: ["All"],
                                       max_number_of_messages: 1)
        resp = client.receive_message(params)
        resp.messages.first
      end

      def queue_url
        @queue_url ||= client.get_queue_url(queue_name: name).queue_url
      end
    end
  end
end
