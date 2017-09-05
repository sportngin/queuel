require 'spec_helper'
module Queuel
  module SQS
    describe Queue do
      let(:message) { double "Message", body: "uhuh", receipt_handle: "receipt", message_attributes: {} }
      let(:client) { double "Aws::SQS::Client" }
      let(:name) { "venues queue" }

      let(:client_with_message) do
        client.tap {|c|
          allow(c).to receive(:receive_message) { double "response", messages: [message] }
          allow(c).to receive(:delete_message)
        }
      end
      let(:client_with_nil_message) do
        client.tap {|c|
          allow(c).to receive(:receive_message) { double "response", messages: [] }
        }
      end

      subject do
        described_class.new client, name, AwsConfig.new({})
      end

      it_should_behave_like "a queue"

      before do
        message.stub_chain :as_sns_message, body: "uhuh"
        allow(client).to receive(:get_queue_url) { double "response", queue_url: "queue url" }
      end

      describe "size" do
        it "should check the queue_connection's approximate_number_of_messages for size" do
          expect(client).to receive(:get_queue_attributes).and_return double("response", attributes: {})
          subject.size
        end
      end

      describe "push" do
        before do
          client.should_receive(:send_message).with(include(message_body: '"foobar"'))
        end

        it "receives a call to build message" do
          subject.push "foobar"
        end

        it "merges options that are passed in" do
          subject.push "foobar", :foo => 'bar'
        end
      end

      describe 'push with attributes' do
        it 'includes message attributes' do
          body  = '{"message":"hello"}'
          attrs = { 'key' => { 'string_value' => 'value', 'data_type' => 'String' } }

          client.should_receive(:send_message).with(include(message_body: body, message_attributes: attrs))

          subject.push({message: 'hello'}, attributes: {key: 'value'})
        end
      end
    end
  end
end
