module Queuel
  module SQS
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

      def pull_message_body
        begin
          decoded_body = decoder.call(message_object.body)
          if decoded_body.key?(:queuel_s3_object)
            s3_transaction(:read, decoded_body[:queuel_s3_object])
          else
            message_object.body
          end
        rescue Queuel::Serialization::Json::SerializationError, TypeError
          raw_body_with_sns_check
        end
      end

      def raw_body_with_sns_check
        begin
          message_object.as_sns_message.body
        rescue ::JSON::ParserError, TypeError
          message_object.body
        end
      end
      private :raw_body_with_sns_check
    end
  end
end
