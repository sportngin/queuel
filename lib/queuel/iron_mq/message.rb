module Queuel
  module IronMq
    class Message < Base::Message
      def raw_body
        @raw_body ||
          (message_object && message_object.body) ||
          encoded_body
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
