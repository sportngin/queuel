require "queuel/aws_config"

module Queuel
  module AwsEngine
    def config
      @config ||= Queuel::AwsConfig.new(credentials)
    end

    def client
      @client ||= client_klass.new(config.client_options)
    end
  end
end
