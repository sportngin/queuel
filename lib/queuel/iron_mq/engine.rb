require "forwardable"
module Queuel
  module IronMq
    class Engine < Base::Engine
      extend Forwardable
      def_delegators :Queuel, :logger

      IronMqMissingError = Class.new(StandardError)

      private

      def try_typhoeus
        require 'typhoeus'
        true
      rescue LoadError
        logger.warn "Typhoeus not found..."
        logger.warn "Typhoeus is recommended for IronMQ"
        false
      end

      def client_klass
        if defined?(::IronMQ::Client)
          try_typhoeus
          ::IronMQ::Client
        else
          begin
            logger.info "Loading IronMQ..."
            require 'iron_mq'
            ::IronMQ::Client
          rescue LoadError
            logger.error "Couldn't find iron_mq gem"
            raise(IronMqMissingError)
          end
        end
      end
    end
  end
end
