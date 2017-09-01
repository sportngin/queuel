require 'spec_helper'
module Queuel
  module IronMq
    describe Queue do
      let(:message) { double "Message", body: "uhuh" }
      let(:client) { double "ClientObject" }
      let(:name) { "venues queue" }

      let(:queue_object_with_message) { double "QueueObject", get: message, peek: [message] }
      let(:queue_object_with_nil_message) { double "QueueObject", get: nil, peek: nil }
      let(:client_with_message) { client.tap {|c| c.stub queue: queue_object_with_message } }
      let(:client_with_nil_message) { client.tap {|c| c.stub queue: queue_object_with_nil_message } }

      subject do
        described_class.new client, name
      end

      it_should_behave_like "a queue"

      describe "with a message" do
        before do
          not_for_null do
            client.stub queue: queue_object_with_message
          end
        end

        describe "size" do
          it "should check the queue_connection for size" do
            client.stub queue: queue_object_with_message
            queue_object_with_message.should_receive(:size)
            subject.size
          end
        end

        describe "peek" do
          before do
            not_for_null do
              client.stub queue: queue_object_with_message
            end
          end

          it "should take options and return an array" do
            subject.peek(option: true).should be_an Array
          end
        end
      end
    end
  end
end
