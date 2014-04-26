module Queuel
  module RabbitMq
    class Message < Base::Message
      def raw_body
        @raw_body ||= message_object ? pull_message_body : push_message_body
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
