require 'spec_helper'
module Queuel
  module IronMq
    describe Message do
      it_should_behave_like "a message"
      describe "initialization with Iron Object" do
        let(:queue_double) { double "Queue" }
        let(:body) { "body" }
        let(:message_object) { double "IronMessage", id: 1, body: body, queue: queue_double }
        subject { described_class.new(message_object) }

        before do
          subject.stub decode_body?: false
        end

        its(:id) { should == 1 }
        its(:body) { should == "body" }
        its(:queue) { should == queue_double }

        describe "with json" do
          let(:body) { '{"username":"jon"}' }
          before do
            subject.stub decode_body?: true
          end

          its(:body) { should == { username: "jon" } }
          its(:raw_body) { should == body }
        end
      end

      describe "using message for encoding" do
        subject { described_class.new }

        describe "setting the body" do
          let(:hash_json) { { username: "jon" } }
          let(:string_json) { '{"username":"jon"}' }

          before do
            subject.body = body
          end

          describe "valid json hash" do
            let(:body) { hash_json }

            its(:body) { should == hash_json }
            its(:raw_body) { should == string_json }
          end
        end

        describe "setting the raw body" do
          let(:hash_json) { { username: "jon" } }
          let(:string_json) { '{"username":"jon"}' }

          before do
            subject.raw_body = raw_body
          end

          describe "valid json string" do
            let(:raw_body) { string_json }

            its(:body) { should == hash_json }
            its(:raw_body) { should == raw_body }
          end

          describe "valid json hash" do
            let(:raw_body) { hash_json }

            its(:body) { should == hash_json }
            its(:raw_body) { should == raw_body }
          end
        end
      end
    end
  end
end
