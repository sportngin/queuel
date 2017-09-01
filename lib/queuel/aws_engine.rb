module Queuel
  module AwsEngine
    def client
      @client ||= client_klass.new(
        region: credentials[:region] || 'us-east-1',
        credentials: Aws::Credentials.new(
          credentials['access_key_id'] || credentials[:access_key_id],
          credentials['secret_access_key'] || credentials[:secret_access_key]
        ))
    end
  end
end
