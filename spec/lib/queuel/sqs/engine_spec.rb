require 'spec_helper'
module Queuel
  module SQS
    describe Engine do
      it_should_behave_like "an engine"

      describe "getting SQS client" do
        its(:client_klass) { should == ::Aws::SQS::Client }
      end
    end
  end
end
