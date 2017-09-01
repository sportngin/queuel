require 'spec_helper'
module Queuel
  module SNS
    describe Queue do
      let(:message) { { 'message' => 'uhuh' } }
      let(:client) { double "ClientObject" }
      let(:name) { "venues queue" }

      subject do
        described_class.new client, name
      end

      it { should respond_to :push }

      it 'publishes a message to the client' do
        expect(client).to receive(:publish).with(topic_arn: name, message: JSON[message])

        subject.push message
      end
    end
  end
end
