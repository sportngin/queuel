require 'forwardable'
module Queuel
  module IronMq
    class Message < Base::Message
      extend Forwardable

      def body
        @body || message_object && message_object.body
      end

      def delete
        message_object.delete
      end

      [:id, :queue].each do |delegate|
        define_method(delegate) do
          instance_variable_get("@#{delegate}") || message_object && message_object.public_send(delegate)
        end
      end
    end
  end
end
