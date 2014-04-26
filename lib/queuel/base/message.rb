require 'forwardable'
module Queuel
  module Base
    class Message
      extend Forwardable
      private
      def_delegators :Queuel,
        :decode_by_default?,
        :encode_by_default?
      attr_accessor :message_object
      attr_accessor :options
      attr_writer :id
      attr_writer :queue

      public

      attr_reader :id
      attr_writer :body
      attr_accessor :raw_body
      attr_reader :queue

      # @argument message_object
      # @argument options hash
      def initialize(message_object = nil, options = {})
        self.message_object = message_object
        self.options = options
      end

      def delete
        raise NotImplementedError, "must define method #delete"
      end

      def body
        @body || decoded_raw_body
      end

      def empty?
        raw_body.to_s.empty?
      end
      alias blank? empty?

      def present?
        !empty?
      end

      private

      def decoder
        options[:decoder] || Queuel.decoder
      end

      def encoder
        options[:encoder] || Queuel.encoder
      end

      def encode?
        options.fetch(:encode) { encode_by_default? }
      end

      def decode?
        options.fetch(:decode) { decode_by_default? }
      end

      def decoded_raw_body
        decode_body? ? decoder.call(raw_body) : raw_body
      end

      def encoded_body
        encode_body? ? encoder.call(body) : body
      end

      def encode_body?
        !@body.to_s.empty? && !encoder.nil? && encode?
      end

      def decode_body?
        !decoder.nil? && decode? && raw_body.is_a?(String)
      end

      def max_bytesize
        options[:max_bytesize] || 64 * 1024
      end

      def push_message_body
        if encoded_body.bytesize > max_bytesize
          key = generate_key
          s3_transaction(:write, key, encoded_body)
          self.body = { 'queuel_s3_object' => key }
        end
        encoded_body
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

      def s3
        @s3 ||= ::AWS::S3.new(
                  :access_key_id => options[:s3_access_key_id],
                  :secret_access_key => options[:s3_secret_access_key] )
      end

      # @method - write or read
      # @args - key and message if writing
      def s3_transaction(method, *args)
        bucket_name = options[:s3_bucket_name]
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

      def generate_key
        key = [
          (Time.now.to_f * 10000).to_i,
          SecureRandom.urlsafe_base64,
          Thread.current.object_id
        ].join('-')
        key
      end

      class NoBucketNameSupplied < Exception; end
      class InsufficientPermissions < StandardError; end
      class BucketDoesNotExistError < StandardError; end
    end
  end
end
