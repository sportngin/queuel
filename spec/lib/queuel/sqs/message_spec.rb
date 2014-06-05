require 'spec_helper'
require 'json'
require 'aws-sdk'
module Queuel
  module SQS
    describe Message do
      it_should_behave_like "a message"
      describe "initialization with SQS Object" do
        let(:queue_double) { double "Queue" }
        let(:body) { "body" }
        let(:message_object) { double "SQSMessage", id: 1, body: body, queue: queue_double }
        subject { described_class.new(message_object) }

        before do
          subject.stub decode_body?: false
          message_object.stub(:as_sns_message).and_raise ::JSON::ParserError
          Queuel.configure { engine :sqs }
        end

        its(:id) { should == 1 }
        its(:body) { should == "body" }
        its(:queue) { should == queue_double }

        it "calls raw_body_with_sns_check if not a json object" do
          subject.should_receive(:raw_body_with_sns_check)
          subject.raw_body
        end

        context "when pulling an oversized message" do
          let(:body) { '{"queuel_s3_object": "whatever"}' }
          let(:message_object) { double "SQSMessage", id: 2, body: body, queue: queue_double }
          subject { described_class.new(message_object) }

          it "calls s3_transaction with read" do
            subject.should_receive(:s3_transaction).with(:read, "whatever")
            subject.raw_body
          end
        end

        context "when pushing an oversized json hash" do
          let(:message) { double("body", bytesize: subject.send(:max_bytesize) + 1) }
          before do
            subject.send("message_object=", nil)
            subject.stub(:encoded_body).and_return message
          end

          it "should call s3_transaction with write" do
            subject.stub(:generate_key).and_return "key"
            subject.should_receive(:s3_transaction).with(:write, "key", message)
            subject.raw_body
          end
        end

        describe "#s3_transaction" do
          it "fails if the s3_bucket_name is not defined" do
            expect{ subject.send(:s3_transaction, 'read') }.to raise_error(Queuel::SQS::Message::NoBucketNameSupplied)
          end

          it "fails if the s3_bucket_name is not a string key" do
            subject.send(:options=, {:s3_bucket_name => 'test'})
            expect{ subject.send(:s3_transaction, 'read') }.to raise_error(Queuel::SQS::Message::NoBucketNameSupplied)
          end

          it "fails without valid s3 creds" do
            subject.send(:options=, {'s3_bucket_name' => 'test'})
            expect{ subject.send(:s3_transaction, 'read') }.to raise_error(AWS::Errors::MissingCredentialsError)
          end
        end

        describe "#s3" do
          subject do
            described_class.new message_object, :s3_access_key_id => "stuff",
                                                :s3_secret_access_key => "derp"
          end

          it "sets the s3 object" do
            AWS::S3.should_receive(:new).with(:access_key_id => "stuff", :secret_access_key => "derp")
            subject.send :s3
          end
        end

        describe "with json" do
          let(:body) { '{"username":"jon"}' }
          before do
            subject.stub decode_body?: true
          end

          its(:body) { should == { username: "jon" } }
          its(:raw_body) { should == body }
        end

        describe "with valid SNS message" do
          let(:sns_body) { "Hello From SNS" }
          before do
            message_object.stub(:as_sns_message).and_return double("SNSMessage", body: sns_body)
          end
          its(:raw_body) { should == sns_body }
          its(:raw_body) { should_not == message_object.body}

          describe "which is json" do
            let(:sns_body) { '{"username":"jon"}' }
            before do
              subject.stub decode_body?: true
              message_object.stub(:as_sns_message).and_return double("SNSMessage", body: sns_body)
            end

            its(:body) { should == { username: "jon" } }
            its(:raw_body) { should == sns_body }
          end
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
