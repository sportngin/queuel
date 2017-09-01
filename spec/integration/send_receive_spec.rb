require 'spec_helper'
require 'securerandom'

RSpec.describe "Send/receive roundtrip test", integration: true do
  let(:message) { { message: "Sending: #{SecureRandom.hex(32)}" } }

  it 'sends and receives a message through the queue system' do
    queue.push message

    sleep 0.1

    received_messages = []
    queue.receive(break_if_nil: true) do |message|
      received_messages << message.body
      true
    end

    sleep 0.1

    expect(received_messages).to include(message)
  end

  describe 'with max_bytesize to force message body to be stored to S3' do
    let(:config) do
      super().tap {|c| c['credentials']['max_bytesize'] = 32 }
    end
    let(:s3) { Queuel::SQS::Message.new(nil, config['credentials']).send(:s3) }
    let(:bucket) { s3.bucket(config['credentials']['s3_bucket_name']) }

    def size
      bucket.objects.each.reduce(0) {|sum,_| sum+1}
    end

    before do
      @initial_bucket_count = size
    end

    it 'sends, stores to S3, receives, and deletes from S3', focus: true do
      queue.push message

      sleep 0.1

      expect(size).to be > @initial_bucket_count

      received_messages = []
      queue.receive(break_if_nil: true) do |message|
        received_messages << message.body
        true
      end

      sleep 0.1

      expect(received_messages).to include(message)

      expect(size).to be <= @initial_bucket_count
    end
  end
end
