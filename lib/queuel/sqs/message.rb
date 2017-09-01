module Queuel
  module SQS
    class Message < Base::Message

      MAX_KNOWN_BYTE_SIZE = 256 * 1024

      def initialize(message_object = nil, options = {})
        super
        @queue = options.delete(:queue)
      end

      def raw_body
        @raw_body ||= message_object ? pull_message : push_message
      end

      def delete
        @queue.delete message_object
        if @queuel_s3_object
          s3_transaction(:delete, @queuel_s3_object)
        end
      end

      [:id, :queue].each do |delegate|
        define_method(delegate) do
          instance_variable_get("@#{delegate}") || message_object && message_object.public_send(delegate)
        end
      end

      private def push_message
        if encoded_body.bytesize > max_bytesize
          key = generate_key
          s3_transaction(:write, key, encoded_body)
          self.body = { 'queuel_s3_object' => key }
        end
        encoded_body
      end

      private def pull_message
        begin
          decoded_body = decoder.call(message_object.body)
          if decoded_body.key?(:queuel_s3_object)
            @queuel_s3_object = decoded_body[:queuel_s3_object]
            s3_transaction(:read, @queuel_s3_object)
          else
            message_object.body
          end
        rescue Queuel::Serialization::Json::SerializationError, TypeError
          raw_body_with_sns_check
        end
      end

      private def max_bytesize
        options['max_bytesize'] || options[:max_bytesize] || MAX_KNOWN_BYTE_SIZE
      end

      private def s3_client_options
        region = options[:s3_region] || options['s3_region'] || options[:region] || options['region']
        access_key_id = options['s3_access_key_id'] || options[:s3_access_key_id] ||
                        options['access_key_id'] || options[:access_key_id]
        secret_access_key = options['s3_secret_access_key'] || options[:s3_secret_access_key] ||
                            options['secret_access_key'] || options[:secret_access_key]
        { region: region, credentials: Aws::Credentials.new(access_key_id, secret_access_key) }
      end

      private def s3
        @s3 ||= ::Aws::S3::Resource.new(client: ::Aws::S3::Client.new(s3_client_options))
      end

      # @method - write or read
      # @args - key and message if writing
      private def s3_transaction(method, *args)
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

      private def s3_read(bucket, *args)
        bucket.object(args[0]).get.body.read
      end

      private def s3_write(bucket, *args)
        bucket.object(args[0]).put(body: args[1])
      end

      private def s3_delete(bucket, *args)
        bucket.object(args[0]).delete
      end

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
