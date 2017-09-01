require 'queuel/base/queue'
require 'forwardable'
module Queuel
  module SNS
    class Queue < Base::Queue
      extend Forwardable

      def push(message, options = {})
        client.publish topic_arn: name, message: build_push_message(message, options)
      end

    end
  end
end
