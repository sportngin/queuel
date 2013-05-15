require 'forwardable'
module Queuel
  module IronMq
    class Message < Base::Message
      extend Forwardable
      def_delegators :message_object, :delete

      def body
        @body || message_object && message_object.msg
      end

      [:id, :queue].each do |delegate|
        define_method(delegate) do
          instance_variable_get("@#{delegate}") || message_object && message_object.public_send(delegate)
        end
      end
    end
  end
end
