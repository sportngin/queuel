module Queuel
  class AWSConstantFinder
    AWSSDKMissingError = Class.new(StandardError)

    extend Forwardable
    def_delegators :Queuel, :logger

    def self.find(*args)
      new(*args).find
    end

    attr_reader :klass_name

    def initialize(klass_name)
      @klass_name = klass_name.to_s.upcase
    end

    def find
      return fetch_const if fetch_const

      logger.info "Loading AWS SDK..."
      fetch_sdk "aws-sdk" do
        return fetch_const if supported_version?
      end

      fail!
    end

    def fail!
      message = "Couldn't find any compatible aws-sdk gem, try installing aws-sdk"
      logger.error message
      raise(AWSSDKMissingError, message)
    end
    private :fail!

    def constants
      ["Aws", klass_name]
    end
    private :constants

    def fetch_const
      constants.inject(Object) { |singleton, string|
        singleton.public_send(:const_get, string)
      }
    rescue NameError, ArgumentError
      nil
    end
    private :fetch_const

    def fetch_sdk(gem_name)
      require gem_name
      yield
    rescue LoadError
      nil
    end
    private :fetch_sdk

    def supported_version?
      ::Aws::VERSION.start_with?("2")
    end
    private :supported_version?
  end
end
