require 'spec_helper'
module Queuel
  module IronMq
    describe Poller do
      it_should_behave_like "a poller"

      let(:queue) { double "Queue" }
      let(:options) { {} }
      let(:block) { double "Callable" }
      subject { described_class.new queue, options, block }

      describe "its options" do
        its(:built_options) { should == { n: 1 } }
        its(:default_options) { should == { n: 1 } }
      end
    end
  end
end
