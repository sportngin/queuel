require 'spec_helper'
module Queuel
  module IronMq
    describe Message do
      it_should_behave_like "a message"
      describe "initialization with Iron Object" do
        let(:queue_double) { double "Queue" }
        let(:message_object) { double "IronMessage", id: 1, msg: "body", queue: queue_double }
        subject { described_class.new(message_object) }

        its(:id) { should == 1 }
        its(:body) { should == "body" }
        its(:queue) { should == queue_double }
      end
    end
  end
end
