require "queuel/aws_constant_finder"
require "queuel/aws_engine"

module Queuel
  module SNS
    class Engine < Base::Engine
      include AwsEngine

      private
      def client_klass
        AWSConstantFinder.find(:sns)::Client
      end
    end
  end
end
