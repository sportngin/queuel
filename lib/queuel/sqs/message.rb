module Queuel
  module SQS
    class Message < Base::Message
      # if message_object exists (not nil), receive the data, otherwise push
      def raw_body
        @raw_body ||= message_object.nil? ? push_message : pull_message
      end

      def generate_key
        key = [
          (Time.now.to_f * 10000).to_i,
          SecureRandom.urlsafe_base64,
          Thread.current.object_id
        ].join('-')
        key
      end

      def push_message
        if encoded_body.bytesize > max_bytesize
          key = generate_key
          write_to_s3(encoded_body, key)
          self.body = { 'queuel_s3_object' => key }
        end
        encoded_body
      end

      def pull_message
        begin
          decoded_body = JSON.parse(message_object.body)
          if decoded_body.key?('queuel_s3_object')
            read_from_s3 decoded_body[:queuel_s3_object]
          else
            message_object.body
          end
        rescue ::JSON::ParserError, TypeError
          raw_body_with_sns_check
        end
      end

      def max_bytesize
        options[:max_bytesize] || 64 * 1024
      end

      def self.s3
        @s3 ||= AWS::S3.new(
                  :access_key_id => options[:access_token],
                  :secret_access_key => options[:secret_access_token] )
      end

      def read_from_s3 key
        object = s3.buckets[options[:bucket_name]].objects[key]
        object.read
      end

      # this assumes you've set up some rules for file expiration on your
      # configured bucket.
      def write_to_s3(message, key)
        begin
          my_bucket = s3.buckets[options[:bucket_name]]
          my_bucket.objects[key].write(message)
        rescue
          raise BucketDoesNotExistError, "Bucket has either expired or does not exist"
        end
      end

      class BucketDoesNotExistError < StandardError
      end

      def delete
        message_object.delete
      end

      [:id, :queue].each do |delegate|
        define_method(delegate) do
          instance_variable_get("@#{delegate}") || message_object && message_object.public_send(delegate)
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
