require 'spec_helper'
module Queuel
  describe Client do
    subject { described_class.new IronMq::Engine, {} }

    it { should respond_to :push }
    it { should respond_to :pop }
    it { should respond_to :receive }
    it { should respond_to :with }

    describe "fails without a queue" do
      it "fails for push" do
        expect { subject.push }.to raise_error NoQueueGivenError
      end

      it "fails for pop" do
        expect { subject.pop }.to raise_error NoQueueGivenError
      end

      it "fails for receive" do
        expect { subject.receive }.to raise_error NoQueueGivenError
      end
    end

    describe "fails without a valid name queue" do
      subject { described_class.new(IronMq::Engine, {}).with "    " }

      it "fails for push" do
        expect { subject.push }.to raise_error NoQueueGivenError
      end

      it "fails for pop" do
        expect { subject.pop }.to raise_error NoQueueGivenError
      end

      it "fails for receive" do
        expect { subject.receive }.to raise_error NoQueueGivenError
      end
    end

    describe "queue swapping" do
      before do
        Queuel.stub default_queue: "default"
      end

      it "can swap queues easily" do
        subject.queue.should == "default"
        subject.with(:new_queue).queue.should == "new_queue"
        subject.queue.should == "default"
      end
    end
  end
end
