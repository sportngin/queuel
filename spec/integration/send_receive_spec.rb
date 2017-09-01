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
    end

    sleep 0.1

    expect(received_messages).to include(message)
  end
end
