require 'spec_helper'
module Queuel
  module IronMq
    describe Engine do
      it_should_behave_like "an engine"

      describe "loading typhoeus" do
        describe "with typhoeus" do
          before do
            subject.stub :require do
              raise LoadError
            end
          end

          its(:try_typhoeus) { should == false }
        end

        describe "without typhoeus" do
          its(:try_typhoeus) { should == true }
        end
      end

      describe "getting iron client" do
        its(:client_klass) { should == ::IronMQ::Client }

        describe "undefined" do
          before do
            subject.stub defined?: false
          end

          its(:client_klass) { should == ::IronMQ::Client }
        end
      end
    end
  end
end
