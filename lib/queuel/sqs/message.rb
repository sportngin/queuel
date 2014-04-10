module Queuel
  module SQS
    class Message < Base::Message
      # if message_object exists (not nil), receive the data, otherwise push
      require 'json'

      def raw_body
        @raw_body ||= message_object.nil? ? push_message : pull_message
      end

      def push_message
        puts "in push message"
        if encoded_body.bytesize > max_bytesize
          key = generate_key
          puts "sending to s3"
          s3_transaction(:write, key, encoded_body)
          self.body = { 'queuel_s3_object' => key }
        end
        encoded_body
      end

      def pull_message
        puts "in pull message"
        begin
          decoded_body = JSON.parse(message_object)
          if decoded_body.key?('queuel_s3_object')
            s3_transaction(:read, decoded_body[:queuel_s3_object])
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

      def s3
        self.class.s3
      end

      # @method - write or read
      # @args - key and message if writing
      def s3_transaction(method, *args)
        bucket_name = options[:bucket_name]
        raise NoBucketNameSupplied if bucket_name.nil?
        my_bucket = s3.buckets[bucket_name]
        if my_bucket.exists?
          begin
            send("s3_#{method}", my_bucket, *args)
          rescue AWS::S3::Errors::AccessDenied => e
            raise InsufficientPermissions, "Unable to read from bucket: #{e.message}"
          end
        else
          raise BucketDoesNotExistError, "Bucket has either expired or does not exist"
        end
      end

      def s3_read(bucket, *args)
        bucket.objects[args[0]].read
      end
      def s3_write(bucket, *args)
        bucket.objects[args[0]].write(args[1])
      end

      def delete
        message_object.delete
      end

      [:id, :queue].each do |delegate|
        define_method(delegate) do
          instance_variable_get("@#{delegate}") || message_object && message_object.public_send(delegate)
        end
      end

      def generate_key
        key = [
          (Time.now.to_f * 10000).to_i,
          SecureRandom.urlsafe_base64,
          Thread.current.object_id
        ].join('-')
        key
      end

      def raw_body_with_sns_check
        begin
          message_object.as_sns_message.body
        rescue ::JSON::ParserError, TypeError
          message_object.body
        end
      end
      private :raw_body_with_sns_check

      class NoBucketNameSupplied < Exception
      end

      class InsufficientPermissions < StandardError
      end

      class BucketDoesNotExistError < StandardError
      end
    end
  end
end
