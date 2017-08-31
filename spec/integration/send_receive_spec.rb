require 'spec_helper'
require 'securerandom'

RSpec.describe "Send/receive roundtrip test", integration: true do
  let(:message) { { message: "Sending: #{SecureRandom.hex(32)}" } }

  it 'sends and receives a message through the queue system' do
    queue.push message

    received_messages = []
    queue.receive(break_if_nil: true) do |message|
      received_messages << message
    end

    expect(received_messages.length).to eq(1)
    expect(received_messages.first.body).to eq(message)
  end
end
