module Queuel
  module SQS
    class Message < Base::Message
      def initialize(message_object = nil, options = {})
        super
        @queue = options.delete(:queue)
        if message_object.respond_to?(:message_attributes)
          self.message_attributes = message_object.message_attributes
        end
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

      def message_attributes
        attributes.map do |k,v|
          [k.to_s, {string_value: v.to_s, data_type: 'String'}]
        end.to_h
      end

      def message_attributes=(mattrs)
        mattrs.each do |k, att|
          attributes[k] = att[:string_value]
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
        queue ? queue.engine_config.max_bytesize : Queuel::AwsConfig::MAX_KNOWN_MESSAGE_SIZE
      end

      private def s3
        @s3 ||= ::Aws::S3::Resource.new(client: ::Aws::S3::Client.new(queue.engine_config.s3_client_options))
      end

      # @method - write or read
      # @args - key and message if writing
      private def s3_transaction(method, *args)
        bucket_name = queue.engine_config.s3_bucket_name
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
