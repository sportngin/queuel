module Queuel
  module IronMq
    class Message < Base::Message
      def raw_body
        @raw_body ||= message_object ? pull_message_body : push_message_body
      end

      def delete
        message_object.delete
      end

      def pull_message_body
        begin
          decoded_body = decoder.call(message_object.body)
          if decoded_body.key?(:queuel_s3_object)
            return s3_transaction(:read, decoded_body[:queuel_s3_object])
          end
        rescue Queuel::Serialization::Json::SerializationError, TypeError
          # do nothing
        end
        message_object.body
      end

      [:id, :queue].each do |delegate|
        define_method(delegate) do
          instance_variable_get("@#{delegate}") || message_object && message_object.public_send(delegate)
        end
      end
    end
  end
end
