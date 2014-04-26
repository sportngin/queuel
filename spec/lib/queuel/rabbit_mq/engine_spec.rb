require 'spec_helper'
module Queuel
  module RabbitMq
    describe Engine do
      it_should_behave_like "an engine"

      describe "getting amqp client" do
        its(:client_klass) { should == ::AMQP::Channel}

        describe "undefined" do
          before do
            subject.stub defined?: false
          end

          its(:client_klass) { should == ::AMQP::Channel }
        end
      end
    end
  end
end
