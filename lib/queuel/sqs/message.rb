module Queuel
  module SQS
    class Message < Base::Message

      MAX_KNOWN_BYTE_SIZE = 256

      def raw_body
        @raw_body ||= message_object ? pull_message : push_message
      end

      def delete
        message_object.delete
      end

      [:id, :queue].each do |delegate|
        define_method(delegate) do
          instance_variable_get("@#{delegate}") || message_object && message_object.public_send(delegate)
        end
      end

      def push_message
        if encoded_body.bytesize > max_bytesize
          key = generate_key
          s3_transaction(:write, key, encoded_body)
          self.body = { 'queuel_s3_object' => key }
        end
        encoded_body
      end
      private :push_message

      def pull_message
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
      private :pull_message

      def max_bytesize
        options['max_bytesize'] || options[:max_bytesize] || Queuel::SQS::Message::MAX_KNOWN_BYTE_SIZE * 1024
      end
      private :max_bytesize

      private def s3_client_options
        region = options[:s3_region] || options['s3_region'] || options[:region] || options['region']
        access_key_id = options['s3_access_key_id'] || options[:s3_access_key_id] ||
                        options['access_key_id'] || options[:access_key_id]
        secret_access_key = options['s3_secret_access_key'] || options[:s3_secret_access_key] ||
                            options['secret_access_key'] || options[:secret_access_key]
        { region: region, credentials: Aws::Credentials.new(access_key_id, secret_access_key) }
      end

      def s3
        @s3 ||= ::Aws::S3::Resource.new(client: ::Aws::S3::Client.new(s3_client_options))
      end
      private :s3

      # @method - write or read
      # @args - key and message if writing
      def s3_transaction(method, *args)
        bucket_name = options[:s3_bucket_name] || options['s3_bucket_name']
        raise NoBucketNameSupplied if bucket_name.nil?
        my_bucket = s3.bucket(bucket_name)
        if my_bucket.exists?
          begin
            send("s3_#{method}", my_bucket, *args)
          rescue Aws::S3::Errors::ServiceError => e
            raise InsufficientPermissions, "Unable to read from bucket: #{e.message}"
          end
        else
          raise BucketDoesNotExistError, "Bucket has either expired or does not exist"
        end
      end
      private :s3_transaction

      def s3_read(bucket, *args)
        bucket.object(args[0]).get.body.read
      end
      private :s3_read

      def s3_write(bucket, *args)
        bucket.object(args[0]).put(body: args[1])
      end
      private :s3_write

      def generate_key
        key = [
          (Time.now.to_f * 10000).to_i,
          SecureRandom.urlsafe_base64,
          Thread.current.object_id
        ].join('-')
        key
      end
      private :generate_key

      def raw_body_with_sns_check
        begin
          message_object.as_sns_message.body
        rescue ::JSON::ParserError, TypeError
          message_object.body
        end
      end
      private :raw_body_with_sns_check


      class NoBucketNameSupplied < Exception; end
      class InsufficientPermissions < StandardError; end
      class BucketDoesNotExistError < StandardError; end
    end
  end
end
