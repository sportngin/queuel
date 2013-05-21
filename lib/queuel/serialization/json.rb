require 'multi_json'
module Queuel
  module Serialization
    module Json
      SerializationError = Class.new StandardError
      class Decoder
        def self.call(body)
          new(body).decode
        end

        def initialize(body)
          @body = body.to_s
        end

        def decode
          MultiJson.load @body, symbolize_keys: true
        rescue MultiJson::LoadError
          raise SerializationError, "Error reading:\n#{@body}"
        end
      end

      class Encoder
        def self.call(body)
          new(body).encode
        end

        def initialize(body)
          @body = body
        end

        def encode
          MultiJson.dump @body
        end
      end
    end
  end
end
