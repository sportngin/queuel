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
    end
  end
end
