require 'spec_helper'
require 'securerandom'

RSpec.describe "Send/receive roundtrip test", integration: true do
  let(:value) { SecureRandom.hex(32) }
  let(:message) { { message: "Sending: #{value}" } }
  let(:attributes) { { "value" => value } }

  it 'sends and receives a message through the queue system' do
    client.push message, attributes: attributes

    sleep 0.5

    received_messages = []
    client.receive(break_if_nil: true) do |message|
      received_messages << message
      true
    end

    sleep 0.5

    expect(received_messages.map(&:body)).to include(message)
    expect(received_messages.select{|m| m.attributes['value'] == value }).to_not be_empty
  end

  describe 'with max_bytesize to force message body to be stored to S3' do
    let(:config) do
      super().tap {|c| c['credentials']['max_bytesize'] = 32 }
    end
    let(:s3) { Queuel::SQS::Message.new(nil, queue: queue).send(:s3) }
    let(:bucket) { s3.bucket(queue.engine_config.s3_bucket_name) }

    def size
      bucket.objects.each.reduce(0) {|sum,_| sum+1}
    end

    before do
      @initial_bucket_count = size
    end

    it 'sends, stores to S3, receives, and deletes from S3' do
      client.push message

      sleep 0.5

      expect(size).to be > @initial_bucket_count

      received_messages = []
      client.receive(break_if_nil: true) do |message|
        received_messages << message.body
        true
      end

      sleep 0.5

      expect(received_messages).to include(message)

      expect(size).to be <= @initial_bucket_count
    end
  end
end
