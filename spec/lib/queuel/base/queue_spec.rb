require 'spec_helper'
module Queuel
  module Base
    describe Queue do
      let(:client) { double "Client" }
      let(:queue_name) { double "some_queue" }
      subject { described_class.new client, queue_name }

      it "fails on non-impleneted push" do
        expect { subject.push }.to raise_error NotImplementedError
      end

      describe "polling" do
        it "delegates polling to a new poller" do
          Poller.any_instance.should_receive(:poll).once
          subject.receive { |m| }
        end
      end
    end
  end
end
