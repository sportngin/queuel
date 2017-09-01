require 'spec_helper'

module Queuel
  describe AWSConstantFinder do
    describe "finding" do
      subject { described_class.new :sqs }

      it "loads the class" do
        subject.find.should eq(::Aws::SQS)
      end
    end
  end
end
