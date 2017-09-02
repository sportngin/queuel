require 'spec_helper'

RSpec.describe Queuel::AwsConfig do
  describe 'when one or both access/secret keys are missing' do
    it 'omits credentials from client options ' do
      expect(described_class.new.client_options).to_not include(:credentials)
    end

    it 'omits credentials from s3 client options ' do
      expect(described_class.new.s3_client_options).to_not include(:credentials)
    end
  end
end
