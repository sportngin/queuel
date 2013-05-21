require 'spec_helper'
module Queuel
  module Serialization
    module Json
      describe Decoder do
        let(:body) { '{"name":"jon"}' }
        subject { described_class.new body }

        it "can call from the class" do
          described_class.call(body).should == { name: "jon" }
        end

        it "can decode from instance" do
          subject.decode.should == { name: "jon" }
        end

        describe "with bad body" do
          let(:body) { '{"name":"jon"' }

          it "fails on bad body" do
            expect { subject.decode }.to raise_error SerializationError
          end
        end
      end

      describe Encoder do
        let(:encoded_body) { '{"name":"jon"}' }
        let(:body) { { "name" => "jon" } }
        subject { described_class.new body }

        it "can call from the class" do
          described_class.call(body).should == encoded_body
        end

        it "can decode from instance" do
          subject.encode.should == encoded_body
        end
      end
    end
  end
end
