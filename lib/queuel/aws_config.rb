module Queuel
  class AwsConfig
    MAX_KNOWN_MESSAGE_SIZE = 256 * 1024

    attr_reader :region, :credentials, :max_bytesize
    attr_reader :s3_bucket_name, :s3_credentials

    def initialize(credentials = {})
      @region = credentials['region'] || credentials[:region] || 'us-east-1'

      credential_args = [
        credentials['access_key_id'] || credentials[:access_key_id],
        credentials['secret_access_key'] || credentials[:secret_access_key]
      ]

      @credentials = Aws::Credentials.new(*credential_args) unless credential_args.include?(nil)

      @max_bytesize = credentials['max_bytesize'] || credentials[:max_bytesize] || MAX_KNOWN_MESSAGE_SIZE

      @s3_bucket_name = credentials[:s3_bucket_name] || credentials['s3_bucket_name']

      s3_credential_args = [
        credentials['s3_access_key_id']     || credentials[:s3_access_key_id],
        credentials['s3_secret_access_key'] || credentials[:s3_secret_access_key]
      ]

      if s3_credential_args.include?(nil)
        @s3_credentials = @credentials
      else
        @s3_credentials = Aws::Credentials.new(*s3_credential_args)
      end

      @s3_region = credentials[:s3_region] || credentials['s3_region'] || @region
    end

    def client_options
      { region: region }.tap do |h|
        h[:credentials] = credentials if credentials
      end
    end

    def s3_client_options
      { region: @s3_region }.tap do |h|
        h[:credentials] = s3_credentials if s3_credentials
      end
    end
  end
end
