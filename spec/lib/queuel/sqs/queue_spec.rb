require 'spec_helper'
module Queuel
  module SQS
    describe Queue do
      let(:message) { double "Message", body: "uhuh" }
      let(:client) { double "Aws::SQS::Client" }
      let(:name) { "venues queue" }

      let(:client_with_message) do
        client.tap {|c|
          allow(c).to receive(:receive_message) { double "response", messages: [message] }
        }
      end
      let(:client_with_nil_message) do
        client.tap {|c|
          allow(c).to receive(:receive_message) { double "response", messages: [] }
        }
      end

      subject do
        described_class.new client, name
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
          client.should_receive(:send_message).with(include(:queue_url, :message_body))
        end

        it "receives a call to build message" do
          subject.should_receive(:build_push_message)
                 .with("foobar", {})
                 .and_return('foobar')

          subject.push "foobar"
        end

        it "merges options that are passed in" do
          subject.should_receive(:build_push_message)
                 .with("foobar", {:foo => 'bar'})
                 .and_return('foobar')

          subject.push "foobar", :foo => 'bar'
        end
      end
    end
  end
end
