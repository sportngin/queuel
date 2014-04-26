require 'spec_helper'
module Queuel
  module RabbitMq
    describe Poller do
      describe "canned behavior" do
        it_should_behave_like "a poller"
      end

      describe "specific to RabbitMQ" do
        let(:queue) { double "Queue" }
        let(:options) { {} }
        let(:block) { double "Callable" }
        subject { described_class.new queue, block, options }

        describe "its options" do
          its(:built_options) { should == { n: 1 } }
          its(:default_options) { should == { n: 1 } }
        end
      end
    end
  end
end
